// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Address;

codeunit 5005397 "Format Adress Comfort"
{

    trigger OnRun()
    begin
    end;

    var
        AddrFormat: Codeunit "Format Address";

    procedure DelifRemindVend(var AddrArray: array[8] of Text[100]; var DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
        with DeliveryReminderHeader do
            AddrFormat.FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure IssDelivRemindVend(var AddrArray: array[8] of Text[100]; var IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header")
    begin
        with IssuedDeliveryReminderHeader do
            AddrFormat.FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;
}

