#!/usr/bin/python3
from brownie import Lottery
from scripts.helpful_scripts import get_account, get_contract


def main():
    # Arrange
    address = get_contract("eth_usd_price_feed").address
    # Act
    price_feed = Lottery.deploy(address, {"from": get_account()})
    # Assert
    value = price_feed.getEntranceFee({"from": get_account()})
    print( address,value)
    # price_feed_contract = PriceFeedConsumer[-1]
    # print(f"Reading data from {price_feed_contract.address}")
    # print(price_feed_contract.getLatestPrice())
