import json

FILE_LISTS = {
    'localhost': ['readme', 'solution'],
    'gateway': ['welcome'],
    'anderson': ['source.py'],
}

MAILBOXES = {
    'alice': ['Salex', 'Scathy'],
    'brian': ['Salice', 'Scathy'],
    'cathy': ['Salice', 'Sbrian'],
    'david': ['Sbrian', 'Dnewhires'],
    'elise': ['Sfrank', 'Slarry'],
    'frank': ['Selise'],
    'gford': ['Sgotonote'],
    'localhost': [],
}

FOLDERNAME = {'S':'sent', 'D':'drafts', 'I':'inbox'}

COMMAND_LISTS = {
    'localhost': ['ls', 'type'],
    'hack': ['atip', 'note', 'gate'],
    'gateway': ['jump', 'ls', 'type'],
    'alice': ['ls', 'mail', 'web'],
    'brian': ['ls', 'mail', 'web'],
    'cathy': ['ls', 'mail', 'web'],
    'david': ['ls', 'mail', 'web'],
    'elise': ['ls', 'mail', 'web'],
    'frank': ['ls', 'mail', 'web'],
    'mail': ['list', 'show'],
    'hr': ['search'],
    'gford': ['ls', 'mail', 'type', 'web'],
    'anderson': ['ls', 'type'],
}

PROGRESS_TRIGGERS = {
    'type readme': [0, 'localhost'],
    'show frank': [1, 'elise.mail'],
    'show elise': [2, 'frank.mail'],
    'show gotonote': [3, 'gford.mail'],
}

LOGIN_MAP = {
    'alice': 'password',
    'brian': 'baseball',
    'cathy': 'love',
    'david': 'baseball',
    'elise': 'hireme',
    'frank': '11111971',
    'anderson': 'matrix',
}

HR_MAP = {
    'elise': 'hireme',
}


HR_FIELDS = {
    'employee': 'Employee',
    'middle': 'Middle Name',
    'last': 'Last Name',
    'type': 'Employee Type',
    'dob': 'DOB',
    'position': 'Position',
}

REPS_MAP = {'gford': 'may'}

WEBSITES = ['overnitedynamite.com', 'reusingnature.com']

scenario = {
    'file_lists': FILE_LISTS,
    'mailboxes': {},
    'command_lists': COMMAND_LISTS,
    'progress_triggers': PROGRESS_TRIGGERS,
    'login_map': LOGIN_MAP,
    'hr_map': HR_MAP,
    'hr_fields': HR_FIELDS,
    'reps_map': REPS_MAP,
    'websites': WEBSITES,
}

for k,v in MAILBOXES.items():
    mbox = []
    for itm in v:
        mbox.append({'item':itm[1:],'body':open('mail/%s/%s.txt' % (k, itm[1:]),'r').read(), 'status':FOLDERNAME[itm[0]]})
    scenario['mailboxes'][k] = mbox

open('scenario.json', 'w').write(json.dumps(scenario))
