from requests import get
from email_utils import send_email

api_url = 'https://hacker-news.firebaseio.com/v0/'
top_stories_url = api_url + 'topstories.json'
item_url = api_url + 'item/{}.json'

def scan_hacker_news(request):
    top_stories = get(top_stories_url).json()
    cloud_stories = []

    for story_id in topstories:
        story = get(item_url.format(story_id)).json()
        if 'cloud' in story['title'].lower():
            cloud_stories.append(story)

    if cloud_stories:
        send_email(cloud_stories)
