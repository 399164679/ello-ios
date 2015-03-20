//
//  AddressBook.swift
//  Ello
//
//  Created by Gordon Fontenot on 3/2/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import AddressBook
import LlamaKit

protocol ContactList {
    var localPeople: [LocalPerson] { get }
}

struct AddressBook: ContactList {
    private let addressBook: ABAddressBook
    let localPeople: [LocalPerson]

    init(addressBook: ABAddressBook) {
        self.addressBook = addressBook
        localPeople = getAllPeopleWithEmailAddresses(addressBook)
    }
}

extension AddressBook {
    static func getAddressBook(completion: Result<AddressBook, AddressBookError> -> ()) {
        var error: Unmanaged<CFError>?
        let ab = ABAddressBookCreateWithOptions(nil, &error)

        if error != nil { completion(failure(.Unauthorized)); return }

        let book = AddressBook(addressBook: ab.takeRetainedValue())

        switch ABAddressBookGetAuthorizationStatus() {
        case .NotDetermined:
            ABAddressBookRequestAccessWithCompletion(book.addressBook) { granted, _ in
                if granted { completion(success(book)) }
                else { completion(failure(.Unauthorized)) }
            }
        case .Authorized: completion(success(book))
        default: completion(failure(.Unauthorized))
        }
    }

    static func needsAuthentication() -> Bool {
        switch ABAddressBookGetAuthorizationStatus() {
        case .NotDetermined: return true
        default: return false
        }
    }
}

private func getAllPeopleWithEmailAddresses(addressBook: ABAddressBook) -> [LocalPerson] {
    return records(addressBook).map { person in
        let name = ABRecordCopyCompositeName(person).takeUnretainedValue()
        let emails = getEmails(person)
        let id = ABRecordGetRecordID(person)
        return LocalPerson(name: name, emails: emails, id: id)
    }.filter { $0.emails.count > 0 }
}

private func getEmails(record: ABRecordRef) -> [String] {
    let multiEmails: ABMultiValueRef = ABRecordCopyValue(record, kABPersonEmailProperty).takeUnretainedValue()
    let emails = ABMultiValueCopyArrayOfAllValues(multiEmails)?.takeUnretainedValue() as? [String]
    return emails ?? []
}

private func records(addressBook: ABAddressBook) -> [ABRecordRef] {
    return ABAddressBookCopyArrayOfAllPeople(addressBook).takeUnretainedValue()
}