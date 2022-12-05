interface WatchItem {
    ID: number
    OwnerID: number
    CreatedAt: Date
    Name: string
    Repo: string
}

interface PullRequest {
    ID: number
    OwnerID: number
    CreatedAt: Date
    Number: number
    Repo: string
    Description: string|null
    Commitid: string|null
}

interface Link {
    ID: number|null
    OwnerID: number|null
    CreatedAt: Date|null
    Url: string
    Name: string
    Clicked: number|null
    Logo_Url: string
}

interface PullRequestIgnore {
    ID: number
    OwnerID: number
    CreatedAt: Date
    Number: number
    Repo: string
}

async function postData(path: string, data: Link|PullRequest|WatchItem|PullRequestIgnore) {
    const response = await fetch(path, {
        method: 'POST',
        body: JSON.stringify(data),
        headers: {'Content-Type': 'application/json; charset=UTF-8'}
    });
    if (response.ok) {
        console.log("added")
    }

    location.reload();

    return response
}

async function deleteItem(path: string, id: number) {
    const response = await fetch(path + id, {
        method: 'DELETE',
        headers: {'Content-Type': 'application/json; charset=UTF-8'}
    });

    if (response.ok) {
        console.log("deleted")
    }

    return response;
}

async function sendLinkData() {
    const ln = document.getElementById("linkname") as HTMLInputElement;
    const lu = document.getElementById('linkurl') as HTMLInputElement;
    const ll = document.getElementById('logourl') as HTMLInputElement;
    let data = {} as Link;
    data.Url = lu.value;
    data.Name = ln.value;
    data.Logo_Url = ll.value;
    await postData('/links', data);
}
async function sendWatchData() {
    const wn = document.getElementById("watchname") as HTMLInputElement;
    const wr = document.getElementById('watchrepo') as HTMLInputElement;
    let data = {} as WatchItem;
    data.Repo = wr.value;
    data.Name = wn.value;
    await postData('/watches', data);
}

async function sendPRData() {
    const pn = document.getElementById("number") as HTMLInputElement;
    const pr = document.getElementById('repo') as HTMLInputElement;
    const pd = document.getElementById("descr") as HTMLInputElement;
    let data = {} as PullRequest;
    data.Repo = pr.value;
    data.Number = parseInt(pd.value, 10);
    data.Description = pd.value;
    await postData('/pullrequests', data);
}

async function addIgnore(number, repo: string) {
    let data = {} as PullRequestIgnore;
    data.Number = number;
    data.Repo = repo;
    await postData('/prignores', data);
}
