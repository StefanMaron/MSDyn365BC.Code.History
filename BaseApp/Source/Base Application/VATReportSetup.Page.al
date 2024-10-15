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
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if users can modify VAT reports that have been submitted to the tax authorities. If the field is left blank, users must create a corrective or supplementary VAT report instead.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series that will be used for standard VAT reports.';
                }
            }
            group(Intermediary)
            {
                Caption = 'Intermediary';
                field("Intermediary VAT Reg. No."; "Intermediary VAT Reg. No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT registration number of your company or your tax representative.';
                }
                field("Intermediary CAF Reg. No."; "Intermediary CAF Reg. No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the registration number of the intermediary in the registry of tax assistance centers (CAF).';
                }
                field("Intermediary Date"; "Intermediary Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the date that the intermediary processed the VAT report.';
                }
            }
            part(Control1130003; "Spesometro Appointments")
            {
                ApplicationArea = VAT;
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

