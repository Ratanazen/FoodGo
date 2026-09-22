import re

with open('backend/core/serializers.py', 'r') as f:
    content = f.read()

serializers = """
class WalletTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletTransaction
        fields = '__all__'

class WalletSerializer(serializers.ModelSerializer):
    transactions = WalletTransactionSerializer(many=True, read_only=True)
    
    class Meta:
        model = Wallet
        fields = ['id', 'user', 'balance', 'transactions']
"""

if "class WalletSerializer" not in content:
    content += "\n" + serializers
    with open('backend/core/serializers.py', 'w') as f:
        f.write(content)
