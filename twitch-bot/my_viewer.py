from twitchio.ext import commands
import os
import sys
import asyncio

CONVERSATION_LIMIT = 20
target_channel = os.environ.get('TARGET_CHANNEL')
bot_name = os.environ.get('BOT_NAME')
token = os.environ.get('TOKEN')

# Get channels from argument or environment variable
if len(sys.argv) > 1:
    channels_list = sys.argv[1:]
else:
    channels_list = [target_channel]

class Bot(commands.Bot):

    conversation = list()

    def __init__(self):
        
        super().__init__(token=token, prefix='!', initial_channels=channels_list)

        print(f'Logged in as | {self.nick}')
        print(channels_list)
        print("OK")

    # Define command to react to Pog messages
    @commands.command(name='pog')
    async def pog_command(self, ctx):
        # Wait for message containing "Pog"
        try:
            msg = await self.wait_for('message', check=lambda m: 'Pog' in m.content, timeout=7.0)
        except asyncio.TimeoutError:
            return
            
        # React with PogChamp messages after 2 second delay
        await asyncio.sleep(2)
        #for i in range(3):
        await msg.add_reaction('PogChamp')

        await ctx.send('Pog reaction complete.')

    # Handle command not found error
    async def on_command_error(self, ctx, error):
        if isinstance(error, commands.CommandNotFound):
            await ctx.send(f'Invalid command. Type !help to see available commands.')

bot = Bot()
bot.run()

    