import re

with open('backend/core/views.py', 'r') as f:
    content = f.read()

wallet_views = """
class WalletViewSet(viewsets.GenericViewSet, viewsets.mixins.RetrieveModelMixin):
    serializer_class = WalletSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Wallet.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['get'])
    def my_wallet(self, request):
        wallet, _ = Wallet.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(wallet)
        return Response(serializer.data)
        
    @action(detail=False, methods=['post'])
    def top_up(self, request):
        amount = request.data.get('amount')
        if not amount:
            return Response({'detail': 'Amount required'}, status=400)
        wallet, _ = Wallet.objects.get_or_create(user=request.user)
        wallet.balance += Decimal(str(amount))
        wallet.save()
        WalletTransaction.objects.create(
            wallet=wallet, amount=amount, transaction_type='deposit', description='Wallet Top Up'
        )
        return Response(self.get_serializer(wallet).data)
"""

if "class WalletViewSet" not in content:
    content = content + "\n" + wallet_views
    with open('backend/core/views.py', 'w') as f:
        f.write(content)
