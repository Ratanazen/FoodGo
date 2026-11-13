import json
from asgiref.sync import async_to_sync
from channels.testing import WebsocketCommunicator
from django.test import TestCase
from config.asgi import application
from core.models import User, Restaurant, Driver, Delivery, Order, Address


class OrderTrackingWebSocketTests(TestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            username='test_ws_customer',
            password='password123',
            role='customer'
        )
        self.owner = User.objects.create_user(
            username='test_resto_owner',
            password='password123',
            role='restaurant_owner'
        )
        self.restaurant = Restaurant.objects.create(
            name='Tracking Test Resto',
            owner=self.owner,
            address='BKK1, Phnom Penh',
            lat=11.5529,
            lng=104.9254
        )
        self.address = Address.objects.create(
            user=self.customer,
            street='Norodom Blvd',
            city='Phnom Penh',
            lat=11.5645,
            lng=104.9328
        )
        self.driver_user = User.objects.create_user(
            username='test_ws_driver',
            password='password123',
            role='driver'
        )
        self.driver = Driver.objects.create(
            user=self.driver_user,
            vehicle_type='Motorcycle (Honda Wave 125i)',
            license_plate='PP-2026',
            is_online=True
        )
        self.order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            address=self.address,
            total_amount=25.00,
            status='on_the_way'
        )
        self.delivery = Delivery.objects.create(
            order=self.order,
            driver=self.driver,
            status='on_the_way'
        )

    def test_order_tracking_websocket_simulator_token(self):
        """Simulate real-time GPS courier route broadcasting over WebSocket."""
        async def _test():
            communicator = WebsocketCommunicator(
                application,
                f'/ws/tracking/{self.order.id}/?token=simulator-token'
            )
            connected, subprotocol = await communicator.connect()
            self.assertTrue(connected)

            # Send GPS Telemetry (Phnom Penh Norodom Blvd)
            telemetry = {
                'lat': 11.5564,
                'lng': 104.9282,
                'bearing': 42.5,
                'speed': 34.0
            }
            await communicator.send_to(text_data=json.dumps(telemetry))

            # Receive broadcasted update
            response = await communicator.receive_from()
            data = json.loads(response)
            self.assertEqual(data.get('type'), 'driver_location')
            self.assertAlmostEqual(data.get('lat'), 11.5564)
            self.assertAlmostEqual(data.get('lng'), 104.9282)
            self.assertAlmostEqual(data.get('bearing'), 42.5)
            self.assertAlmostEqual(data.get('speed'), 34.0)

            await communicator.disconnect()

        async_to_sync(_test)()

    def test_assigned_driver_jwt_location_broadcast(self):
        """Assigned driver with real JWT token broadcasts coordinates to customer listener."""
        from rest_framework_simplejwt.tokens import RefreshToken

        async def _test():
            driver_token = str(RefreshToken.for_user(self.driver_user).access_token)
            customer_token = str(RefreshToken.for_user(self.customer).access_token)

            # Customer listener connects
            customer_comm = WebsocketCommunicator(
                application,
                f'/ws/tracking/{self.order.id}/?token={customer_token}'
            )
            c_connected, _ = await customer_comm.connect()
            self.assertTrue(c_connected)

            # Driver broadcaster connects
            driver_comm = WebsocketCommunicator(
                application,
                f'/ws/tracking/{self.order.id}/?token={driver_token}'
            )
            d_connected, _ = await driver_comm.connect()
            self.assertTrue(d_connected)

            # Driver sends location
            telemetry = {
                'lat': 11.5601,
                'lng': 104.9315,
                'bearing': 88.0,
                'speed': 38.0
            }
            await driver_comm.send_to(text_data=json.dumps(telemetry))

            # Customer receives location
            c_response = await customer_comm.receive_from()
            c_data = json.loads(c_response)
            self.assertEqual(c_data.get('type'), 'driver_location')
            self.assertAlmostEqual(c_data.get('lat'), 11.5601)
            self.assertAlmostEqual(c_data.get('lng'), 104.9315)
            self.assertAlmostEqual(c_data.get('bearing'), 88.0)
            self.assertAlmostEqual(c_data.get('speed'), 38.0)

            await driver_comm.disconnect()
            await customer_comm.disconnect()

        async_to_sync(_test)()

    def test_order_tracking_websocket_rejects_missing_token(self):
        """Websocket rejects connection without authorization token."""
        async def _test():
            communicator = WebsocketCommunicator(
                application,
                f'/ws/tracking/{self.order.id}/'
            )
            connected, _ = await communicator.connect()
            self.assertFalse(connected)

        async_to_sync(_test)()
