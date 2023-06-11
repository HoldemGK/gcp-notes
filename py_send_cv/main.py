import re
import time
from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

driver_path = '/d/GK/Proj/packs/chromedriver_win32/chromedriver.exe'
url = 'https://cloud.google.com/find-a-partner/?location=canada&products=Google%20Cloud&products=Google%20Cloud%20Platform&regions=NA_REGION'

# Set up the Selenium web driver with ChromeDriverManager
options = Options()
options.add_experimental_option('excludeSwitches', ['enable-logging'])
driver = webdriver.Chrome(service=Service(ChromeDriverManager(path=driver_path).install()), options=options)
driver.implicitly_wait(5)
driver.get(url)

def getting_number():
    results_count_element = driver.find_element(By.XPATH, '//*[@id="maincontent"]/app-directory/ps-responsive-content[2]/div/app-search-results/div[1]')
    if results_count_element:
        # Extract the pattern using regular expressions
        pattern = r"Displaying (\d+) of (\d+) results"
        match = re.search(pattern, results_count_element.text)

        if match:
            x = int(match.group(1))
            y = int(match.group(2))
            print("X:", x)
            print("Y:", y)
        else:
            print("Pattern not found.")
            exit(1)
    else:
        print("Element not found.")
        exit(1)

def load_all_cards():
    load_partners = driver.find_element(By.XPATH, '//*[@id="maincontent"]/app-directory/ps-responsive-content[2]/div/app-search-results/div[3]/button')
    while True:
      try:
        time.sleep(1)
        load_partners.click()
        time.sleep(1)
        getting_number()
      except NoSuchElementException:
         break

load_all_cards()
#time.sleep(7)
# Define the "Load more partners" button element
# load_more_button = WebDriverWait(driver, 20).until(
#     EC.presence_of_element_located((By.XPATH, "//span[text()='Load more partners']"))
# )

# # Click the "Load more partners" button until all cards are loaded
# while True:
#     try:
#         load_more_button.click()
#         load_more_button = WebDriverWait(driver, 10).until(
#             EC.presence_of_element_located((By.XPATH, "//span[text()='Load more partners']"))
#         )
#     except:
#         break

# # Extract the loaded partner cards
# partner_cards = driver.find_elements(By.XPATH, "//div[@class='partner-card']")

# # Process the partner cards as desired
# for card in partner_cards:
#     # Process each partner card
#     pass

# Close the browser
driver.quit()