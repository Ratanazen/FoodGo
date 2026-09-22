import re

with open('backend/core/views.py', 'r') as f:
    content = f.read()

replacement = """
        subtotal = sum(
            (item.food_item.price * item.quantity for item in cart_items),
            Decimal('0.00'),
        )
        total_amount = subtotal + restaurant.delivery_fee
        
        wallet, _ = Wallet.objects.get_or_create(user=user)
        if wallet.balance < total_amount:
            raise ValidationError({'payment': ['Insufficient wallet balance. Please top up your wallet.']})
        
        wallet.balance -= total_amount
        wallet.save()
        WalletTransaction.objects.create(
            wallet=wallet, amount=total_amount, transaction_type='payment', description='Order Payment'
        )

        order = serializer.save(customer=user, total_amount=total_amount)
"""

content = content.replace("""        subtotal = sum(
            (item.food_item.price * item.quantity for item in cart_items),
            Decimal('0.00'),
        )
        order = serializer.save(customer=user, total_amount=subtotal + restaurant.delivery_fee)""", replacement)

with open('backend/core/views.py', 'w') as f:
    f.write(content)
