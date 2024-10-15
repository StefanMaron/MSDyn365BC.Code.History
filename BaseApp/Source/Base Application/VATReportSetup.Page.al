page 743 "VAT Report Setup"
{
    ApplicationArea = VAT;
    Caption = 'VAT Report Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "VAT Report Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Modify Submitted Reports"; "Modify Submitted Reports")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if users can modify VAT reports that have been submitted to the tax authorities. If the field is left blank, users must create a corrective or supplementary VAT report instead.';
                }
                field("Export Cancellation Lines"; "Export Cancellation Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT report includes export cancellation lines.';
                }
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company to be included on the VAT report.';
                }
                field("Company Address"; "Company Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the company that is submitting the VAT report.';
                }
                field("Company City"; "Company City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company for the VAT report.';
                }
                field("Report VAT Note"; "Report VAT Note")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT Note field is available for reporting from the VAT Return card page.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series that will be used for standard VAT reports.';
                }
            }
            group(ZIVIT)
            {
                Caption = 'ZIVIT';
                field("Source Identifier"; "Source Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the 11 character alphabetic ID that is provided when you register at the processing agency (ZIVIT).';
                }
                field("Transmission Process ID"; "Transmission Process ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the 3 character alphanumeric ID of the transmission process.';
                }
                field("Supplier ID"; "Supplier ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the 3 character alphanumeric ID of the supplier.';
                }
                field(Codepage; Codepage)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code page for the formats in which you can submit a dataset for a VAT report.';
                }
                field("Registration ID"; "Registration ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration ID of the EU Sales List document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

