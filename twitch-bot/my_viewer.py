from twitchio.ext import commands
import os 
import time

CONVERSATION_LIMIT = 20
channel_list = ["${TARGET}"]
bot_name = '${BOT_NAME}'

class Bot(commands.Bot):

    conversation = list()

    def __init__(self):
        
        super().__init__(token='${OATH_TOKEN}', prefix='!', initial_channels=channel_list)

    async def event_ready(self):

        print(f'Logged in as | {self.nick}')

        #await self.join_channels(channel_list)
        print(channel_list)
        print("OK")

bot = Bot()
bot.run()

    