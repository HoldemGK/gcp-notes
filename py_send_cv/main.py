import re
import time
from selenium import webdriver
from bs4 import BeautifulSoup

driver_path = '/d/GK/Proj/packs/chromedriver_win32/chromedriver.exe'
url = 'https://cloud.google.com/find-a-partner/?location=canada&products=Google%20Cloud&products=Google%20Cloud%20Platform&regions=NA_REGION'
file_path = './bin/index.html'

def parse_html_file(file_path):
    with open(file_path, "r", encoding="utf8") as file:
        # Read the content of the HTML file
        content = file.read()

        # Create a BeautifulSoup object to parse the HTML content
        soup = BeautifulSoup(content, "html.parser")

        # Find all elements with data-test-id="partner-link"
        partner_links = soup.find_all(attrs={"data-test-id": "partner-link"})

        # Extract the href values and store them in a list
        href_list = [link.get("href") for link in partner_links]

        return href_list

href_list = parse_html_file(file_path)

print (href_list)