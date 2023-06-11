import time
import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Configure the Chrome webdriver
driver = webdriver.Chrome()

# Open the partner directory page
url = 'https://cloud.google.com/find-a-partner/?location=canada&products=Google%20Cloud&products=Google%20Cloud%20Platform&regions=NA_REGION'
driver.get(url)

# Wait for the page to load
wait = WebDriverWait(driver, 10)
wait.until(EC.visibility_of_element_located((By.CSS_SELECTOR, '.cloud-search-results .cloud-search-result-card')))

# Function to extract email addresses from a partner card
def extract_emails(card):
    email_links = card.find_all('a', href=lambda href: href and href.startswith('mailto:'))
    emails = [link['href'].split(':', 1)[1] for link in email_links]
    return emails

# Scroll and load more partners
while True:
    cards = driver.find_elements(By.CSS_SELECTOR, '.cloud-search-results .cloud-search-result-card')
    for card in cards:
        emails = extract_emails(card)
        if emails:
            print(emails)

    try:
        # Click the "Load more partners" button
        load_more_button = driver.find_element(By.CSS_SELECTOR, '.cloud-load-more-button')
        load_more_button.click()

        # Wait for the new partners to load
        time.sleep(3)  # Adjust the delay as needed
    except NoSuchElementException:
        break

# Close the browser
driver.quit()
