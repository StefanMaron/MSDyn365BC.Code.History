﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using System.Security.User;

page 249 "VAT Registration Log"
{
    Caption = 'VAT Registration Log';
    DataCaptionFields = "Account Type", "Account No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "VAT Registration Log";
    SourceTableView = sorting("Entry No.")
                      order(descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT registration number that you entered in the VAT Registration No. field on a customer, vendor, or contact card.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the account type of the customer or vendor whose VAT registration number is verified.';
                    Visible = false;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the account number of the customer or vendor whose VAT registration number is verified.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the verification action.';
                }
                field("Verified Date"; Rec."Verified Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies when the VAT registration number was verified.';
                }
                field("Verified Name"; Rec."Verified Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer, vendor, or contact whose VAT registration number was verified.';
                    Visible = false;
                }
                field("Verified Address"; Rec."Verified Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the address of the customer, vendor, or contact whose VAT registration number was verified.';
                    Visible = false;
                }
                field("Verified Street"; Rec."Verified Street")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the street of the customer, vendor, or contact whose VAT registration number was verified. ';
                    Visible = false;
                }
                field("Verified Postcode"; Rec."Verified Postcode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postcode of the customer, vendor, or contact whose VAT registration number was verified. ';
                    Visible = false;
                }
                field("Verified City"; Rec."Verified City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the customer, vendor, or contact whose VAT registration number was verified. ';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Request Identifier"; Rec."Request Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the request identifier of the VAT registration number validation service.';
                }
                field("Details Status"; Rec."Details Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the details validation.';
                    Enabled = DetailsExist;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Verify VAT Registration No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Verify VAT Registration No.';
                Image = Start;
                RunObject = Codeunit "VAT Lookup Ext. Data Hndl";
                ToolTip = 'Verify a Tax registration number. If the number is verified the status field contains the value Valid.';
            }
            action(ValidationDetails)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Validation Details';
                Enabled = DetailsExist;
                Image = List;
                ToolTip = 'Open the list of fields that have been processed by the VAT registration no. validation service.';

                trigger OnAction()
                begin
                    Rec.OpenModifyDetails();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Verify VAT Registration No._Promoted"; "Verify VAT Registration No.")
                {
                }
                actionref(ValidationDetails_Promoted; ValidationDetails)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        DetailsExist := Rec."Details Status" <> Rec."Details Status"::"Not Verified";
    end;

    var
        DetailsExist: Boolean;
}

