import requests
import pytest

from api import gitlab

ROOT_URL = "https://gitlab.com/"


def test_gitlab_basic_get(requests_mock):
    expected_url = "http://gitlab.com/api/v4/user?per_page=20"
    expected_json = {"username": "codeEmitter"}
    requests_mock.register_uri("GET", expected_url, json=expected_json, status_code=200, headers={
        "RateLimit-Observed": "500",
        "RateLimit-Limit": "600",
        "RateLimit-ResetTime": "1/1/2020",
        "Content-Type": "application/json"})
    target = gitlab.GitLab(ROOT_URL, lambda: requests.Session())
    assert target.get(expected_url) == expected_json
    assert requests_mock.called is True
    assert requests_mock.call_count == 1
    assert requests_mock.request_history[0].method == "GET"
    assert requests_mock.request_history[0].url == expected_url


def test_gitlab_pages_requests_properly(requests_mock):
    expected_url_initial = "http://gitlab.com/api/v4/groups/1?per_page=20"
    expected_url_paged = "https://gitlab.com/api/v4/groups/1/members?id=1&page=2&per_page=20"
    request1_json = {"username": "codeEmitter"}
    request2_json = {"username": "jsmith"}
    url1_headers = {
        "RateLimit-Observed": "500",
        "RateLimit-Limit": "600",
        "RateLimit-ResetTime": "1/1/2020",
        "Content-Type": "application/json",
        "Link": f'<{expected_url_paged}>; rel="next", <https://gitlab.com/api/v4/groups/1/members?id=1&page=1&per_page=20>; rel="first", <https://gitlab.com/api/v4/groups/1/members?id=1&page=2&per_page=20>; rel="last"'
    }
    url2_headers = {
        "RateLimit-Observed": "500",
        "RateLimit-Limit": "600",
        "RateLimit-ResetTime": "1/1/2020",
        "Content-Type": "application/json",
        "Link": '<https://gitlab.com/api/v4/groups/3786502/members?id=3786502&page=1&per_page=20>; rel="prev", <https://gitlab.com/api/v4/groups/3786502/members?id=3786502&page=1&per_page=20>; rel="first", <https://gitlab.com/api/v4/groups/3786502/members?id=3786502&page=2&per_page=20>; rel="last"'
    }

    requests_mock.register_uri("GET", expected_url_initial, json=[request1_json], status_code=200, headers=url1_headers)
    requests_mock.register_uri("GET", expected_url_paged, json=[request2_json], status_code=200, headers=url2_headers)
    target = gitlab.GitLab(ROOT_URL, lambda: requests.Session())
    assert target.get(expected_url_initial) == [request1_json, request2_json]
    assert requests_mock.called is True
    assert requests_mock.call_count == 2
    assert requests_mock.request_history[0].method == "GET"
    assert requests_mock.request_history[0].url == expected_url_initial
    assert requests_mock.request_history[1].method == "GET"
    assert requests_mock.request_history[1].url == expected_url_paged


def test_gitlab_handles_a_unpaged_timeout_correctly(requests_mock):
    with pytest.raises(requests.exceptions.ConnectTimeout):
        expected_url_1 = "http://gitlab.com/api/v4/members/1?per_page=20"
        expected_url_2 = "http://gitlab.com/api/v4/members/1?per_page=10"
        expected_url_3 = "http://gitlab.com/api/v4/members/1?per_page=5"
        expected_url_4 = "http://gitlab.com/api/v4/members/1?per_page=1"
        requests_mock.register_uri("GET", expected_url_1, exc=requests.exceptions.ConnectTimeout)
        requests_mock.register_uri("GET", expected_url_2, exc=requests.exceptions.ConnectTimeout)
        requests_mock.register_uri("GET", expected_url_3, exc=requests.exceptions.ConnectTimeout)
        requests_mock.register_uri("GET", expected_url_4, exc=requests.exceptions.ConnectTimeout)
        target = gitlab.GitLab(ROOT_URL, lambda: requests.Session())
        target.get(expected_url_1)


def test_gitlab_handles_paged_timeout_correctly(requests_mock):
    with pytest.raises(requests.exceptions.ConnectTimeout):
        expected_url_initial = "http://gitlab.com/api/v4/groups/1"
        expected_url_paged_1 = "https://gitlab.com/api/v4/groups/1/members?id=1&page=2&per_page=20"
        expected_url_paged_2 = "https://gitlab.com/api/v4/groups/1/members?id=1&page=2&per_page=10"
        expected_url_paged_3 = "https://gitlab.com/api/v4/groups/1/members?id=1&page=2&per_page=5"
        expected_url_paged_4 = "https://gitlab.com/api/v4/groups/1/members?id=1&page=2&per_page=1"
        request1_json = {"username": "codeEmitter"}
        url1_headers = {
            "RateLimit-Observed": "500",
            "RateLimit-Limit": "600",
            "RateLimit-ResetTime": "1/1/2020",
            "Content-Type": "application/json",
            "Link": f'<{expected_url_paged_1}>; rel="next", <https://gitlab.com/api/v4/groups/1/members?id=1&page=1&per_page=20>; rel="first", <https://gitlab.com/api/v4/groups/1/members?id=1&page=2&per_page=20>; rel="last"'
        }

        requests_mock.register_uri("GET", expected_url_initial, json=[request1_json], status_code=200,
                                   headers=url1_headers)
        requests_mock.register_uri("GET", expected_url_paged_1, exc=requests.exceptions.ConnectTimeout)
        requests_mock.register_uri("GET", expected_url_paged_2, exc=requests.exceptions.ConnectTimeout)
        requests_mock.register_uri("GET", expected_url_paged_3, exc=requests.exceptions.ConnectTimeout)
        requests_mock.register_uri("GET", expected_url_paged_4, exc=requests.exceptions.ConnectTimeout)
        target = gitlab.GitLab(ROOT_URL, lambda: requests.Session())
        target.get(expected_url_initial)


def test_gitlab_handles_responses_without_headers_correctly(requests_mock):
    expected_url = "http://gitlab.com/api/v4/user?per_page=20"
    requests_mock.register_uri("GET", expected_url, status_code=504, reason="Gateway timeout",
                               headers={"Content-Type": "application/text"})
    target = gitlab.GitLab(ROOT_URL, lambda: requests.Session())
    assert target.get(expected_url) is False
    assert requests_mock.called is True
    assert requests_mock.call_count == 1
    assert requests_mock.request_history[0].method == "GET"
    assert requests_mock.request_history[0].url == expected_url


def test_gitlab_handles_dynamic_page_size_reductions_with_success(requests_mock):
    expected_url_initial = "https://gitlab.com/api/v4/groups/1/members?per_page=20"
    expected_url_paged = "https://gitlab.com/api/v4/groups/1/members?per_page=10"
    request2_json = {"username": "jsmith"}
    url2_headers = {
        "RateLimit-Observed": "500",
        "RateLimit-Limit": "600",
        "RateLimit-ResetTime": "1/1/2020",
        "Content-Type": "application/json",
        "Link": '<https://gitlab.com/api/v4/groups/1/members?id=1&page=1&per_page=20>; rel="prev", <https://gitlab.com/api/v4/groups/1/members?id=1&page=1&per_page=20>; rel="first", <https://gitlab.com/api/v4/groups/1/members?id=1&page=2&per_page=20>; rel="last"'
    }
    requests_mock.register_uri("GET", expected_url_initial, exc=requests.exceptions.ConnectTimeout, complete_qs=True)
    requests_mock.register_uri("GET", expected_url_paged, json=[request2_json], status_code=200, headers=url2_headers,
                               complete_qs=True)
    target = gitlab.GitLab(ROOT_URL, lambda: requests.Session())
    response = target.get(expected_url_initial)
    assert response == [request2_json]
    assert requests_mock.called is True
    assert requests_mock.call_count == 3
    assert requests_mock.request_history[0].method == "GET"
    assert requests_mock.request_history[0].url == expected_url_initial
    assert requests_mock.request_history[1].method == "GET"
    assert requests_mock.request_history[1].url == expected_url_initial  # retry attempt
    assert requests_mock.request_history[2].method == "GET"
    assert requests_mock.request_history[2].url == expected_url_paged  # success with dynamic page size reduction


def test_gitlab_handles_dynamic_page_size_reductions_with_failure(requests_mock):
    with pytest.raises(requests.exceptions.ConnectTimeout):
        expected_url_initial = "https://gitlab.com/api/v4/groups/1/members?per_page=20"
        expected_url_paged_1 = "https://gitlab.com/api/v4/groups/1/members?per_page=10"
        expected_url_paged_2 = "https://gitlab.com/api/v4/groups/1/members?per_page=5"
        expected_url_paged_3 = "https://gitlab.com/api/v4/groups/1/members?per_page=2"
        expected_url_paged_4 = "https://gitlab.com/api/v4/groups/1/members?per_page=1"
        url2_headers = {
            "RateLimit-Observed": "500",
            "RateLimit-Limit": "600",
            "RateLimit-ResetTime": "1/1/2020",
            "Content-Type": "application/json",
            "Link": '<https://gitlab.com/api/v4/groups/1/members?id=1&page=1&per_page=20>; rel="prev", <https://gitlab.com/api/v4/groups/1/members?id=1&page=1&per_page=20>; rel="first", <https://gitlab.com/api/v4/groups/1/members?id=1&page=2&per_page=20>; rel="last"'
        }
        requests_mock.register_uri("GET", expected_url_initial, exc=requests.exceptions.ConnectTimeout,
                                   complete_qs=True)
        requests_mock.register_uri("GET", expected_url_paged_1, exc=requests.exceptions.ConnectTimeout,
                                   complete_qs=True)
        requests_mock.register_uri("GET", expected_url_paged_2, exc=requests.exceptions.ConnectTimeout,
                                   complete_qs=True)
        requests_mock.register_uri("GET", expected_url_paged_3, exc=requests.exceptions.ConnectTimeout,
                                   complete_qs=True)
        requests_mock.register_uri("GET", expected_url_paged_4, exc=requests.exceptions.ConnectTimeout,
                                   complete_qs=True)
        target = gitlab.GitLab(ROOT_URL, lambda: requests.Session())
        target.get(expected_url_initial)
