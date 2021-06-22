page 249 "VAT Registration Log"
{
    Caption = 'VAT Registration Log';
    DataCaptionFields = "Account Type", "Account No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "VAT Registration Log";
    SourceTableView = SORTING("Entry No.")
                      ORDER(Descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT registration number that you entered in the VAT Registration No. field on a customer, vendor, or contact card.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the account type of the customer or vendor whose VAT registration number is verified.';
                    Visible = false;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the account number of the customer or vendor whose VAT registration number is verified.';
                    Visible = false;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the verification action.';
                }
                field("Verified Date"; "Verified Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies when the VAT registration number was verified.';
                }
                field("Verified Name"; "Verified Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer, vendor, or contact whose VAT registration number was verified.';
                }
                field("Verified Address"; "Verified Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the address of the customer, vendor, or contact whose VAT registration number was verified.';
                }
                field("Verified Street"; "Verified Street")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the street of the customer, vendor, or contact whose VAT registration number was verified. ';
                }
                field("Verified Postcode"; "Verified Postcode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postcode of the customer, vendor, or contact whose VAT registration number was verified. ';
                }
                field("Verified City"; "Verified City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the customer, vendor, or contact whose VAT registration number was verified. ';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Request Identifier"; "Request Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the request identifier of the VAT registration number validation service.';
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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Codeunit "VAT Lookup Ext. Data Hndl";
                ToolTip = 'Verify a Tax registration number. If the number is verified the status field contains the value Valid.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        if FindFirst then;
    end;
}

