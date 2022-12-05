var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
function postData(path, data) {
    return __awaiter(this, void 0, void 0, function () {
        var response;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, fetch(path, {
                        method: 'POST',
                        body: JSON.stringify(data),
                        headers: { 'Content-Type': 'application/json; charset=UTF-8' }
                    })];
                case 1:
                    response = _a.sent();
                    if (response.ok) {
                        console.log("added");
                    }
                    location.reload();
                    return [2 /*return*/, response];
            }
        });
    });
}
function deleteItem(path, id) {
    return __awaiter(this, void 0, void 0, function () {
        var response;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, fetch(path + id, {
                        method: 'DELETE',
                        headers: { 'Content-Type': 'application/json; charset=UTF-8' }
                    })];
                case 1:
                    response = _a.sent();
                    if (response.ok) {
                        console.log("deleted");
                    }
                    return [2 /*return*/, response];
            }
        });
    });
}
function sendLinkData() {
    return __awaiter(this, void 0, void 0, function () {
        var ln, lu, ll, data;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    ln = document.getElementById("linkname");
                    lu = document.getElementById('linkurl');
                    ll = document.getElementById('logourl');
                    data = {};
                    data.Url = lu.value;
                    data.Name = ln.value;
                    data.Logo_Url = ll.value;
                    return [4 /*yield*/, postData('/links', data)];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function sendWatchData() {
    return __awaiter(this, void 0, void 0, function () {
        var wn, wr, data;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    wn = document.getElementById("watchname");
                    wr = document.getElementById('watchrepo');
                    data = {};
                    data.Repo = wr.value;
                    data.Name = wn.value;
                    return [4 /*yield*/, postData('/watches', data)];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function sendPRData() {
    return __awaiter(this, void 0, void 0, function () {
        var pn, pr, pd, data;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    pn = document.getElementById("number");
                    pr = document.getElementById('repo');
                    pd = document.getElementById("descr");
                    data = {};
                    data.Repo = pr.value;
                    data.Number = parseInt(pd.value, 10);
                    data.Description = pd.value;
                    return [4 /*yield*/, postData('/pullrequests', data)];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function addIgnore(number, repo) {
    return __awaiter(this, void 0, void 0, function () {
        var data;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    data = {};
                    data.Number = number;
                    data.Repo = repo;
                    return [4 /*yield*/, postData('/prignores', data)];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
