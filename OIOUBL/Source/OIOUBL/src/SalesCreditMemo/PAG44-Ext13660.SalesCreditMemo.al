// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

pageextension 13660 "OIOUBL-Sales Credit Memo" extends "Sales Credit Memo"
{
    layout
    {

        addafter("Sell-to Contact No.")
        {
            field("OIOUBL-Sell-to Contact Phone No."; "OIOUBL-Sell-to Contact Phone No.")
            {
                Caption = 'Contact Phone No.';
                Tooltip = 'Specifies the telephone number of the contact person at the customer.';
                ApplicationArea = Basic, Suite;
            }
            field("OIOUBL-Sell-to Contact Fax No."; "OIOUBL-Sell-to Contact Fax No.")
            {
                Caption = 'Contact Fax No.';
                Tooltip = 'Specifies the fax number of the contact person at the customer.';
                ApplicationArea = Basic, Suite;
            }
            field("OIOUBL-Sell-to Contact E-Mail"; "OIOUBL-Sell-to Contact E-Mail")
            {
                Caption = 'Contact E-Mail';
                Tooltip = 'Specifies the email address of the contact person at the customer.';
                ApplicationArea = Basic, Suite;
            }
            field("OIOUBL-Sell-to Contact Role"; "OIOUBL-Sell-to Contact Role")
            {
                Caption = 'Contact Role';
                Tooltip = 'Specifies the role of the contact person at the customer.';
                ApplicationArea = Basic, Suite;
            }
        }

        addafter("Bill-to Contact")
        {
            field("OIOUBL-GLN"; "OIOUBL-GLN")
            {
                Tooltip = 'Specifies the GLN location number for the customer.';
                ApplicationArea = Basic, Suite;
            }
            field("OIOUBL-Account Code"; "OIOUBL-Account Code")
            {
                Tooltip = 'Specifies the account code of the customer.';
                ApplicationArea = Basic, Suite;

                trigger OnValidate();
                begin
                    CurrPage.SalesLines.Page.Update(true);
                end;
            }
            field("OIOUBL-Profile Code"; "OIOUBL-Profile Code")
            {
                Tooltip = 'Specifies the profile that the customer requires for electronic documents.';
                ApplicationArea = Basic, Suite;
            }
        }
    }
}