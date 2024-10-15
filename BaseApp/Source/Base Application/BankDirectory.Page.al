page 11501 "Bank Directory"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Directory';
    PageType = List;
    SourceTable = "Bank Directory";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Clearing No."; "Clearing No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the clearing number and therefore identifies the bank.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the bank.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code for the bank.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first address line for the bank.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the second address line.';
                }
                field(Group; Group)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the group to which a bank or financial institution belongs.';
                }
                field("No of Outlets"; "No of Outlets")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of outlets.';
                }
                field("Clearing Main Office"; "Clearing Main Office")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the clearing number for the main office.';
                }
                field("Bank Type"; "Bank Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies these bank types.';
                }
                field("SIC No."; "SIC No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BC number for use in SIC and euroSIC.';
                }
                field("SIC Member"; "SIC Member")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the bank / institution is an SIC participant or not.';
                }
                field("euroSIC Member"; "euroSIC Member")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the bank / institution is an euroSIC participant or not.';
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which language code is used.';
                }
                field(Country; Country)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code for foreign banks.';
                }
                field("Short Name"; "Short Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the short name of the bank.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the bank.';
                }
                field("SWIFT Address"; "SWIFT Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT address from the SWIFT directory.';
                }
                field("Valid from"; "Valid from")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date, since when the record entries are valid.';
                }
                field("Sight Deposit Account"; "Sight Deposit Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal account number from the directory.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Import Bank Directory")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Bank Directory';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Import information about the bank accounts of customers and vendors into the bank directory.';

                    trigger OnAction()
                    begin
                        Clear(ImportBankDirectory);
                        ImportBankDirectory.RunModal();
                    end;
                }
            }
        }
    }

    var
        ImportBankDirectory: Report "Import Bank Directory";
}

