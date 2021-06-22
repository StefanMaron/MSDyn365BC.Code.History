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
                field("EC Sales List No. Series"; "No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("VAT Return No. Series"; "VAT Return No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series that is used for VAT return records.';
                }
                field("VAT Return Period No. Series"; "VAT Return Period No. Series")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number series that is used for the VAT return period records.';
                }
            }
            group("Return Period")
            {
                field("Report Version"; "Report Version")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT report version that is used for the VAT reporting periods.';
                }
                field("Period Reminder Calculation"; "Period Reminder Calculation")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a formula that is used to notify about an open VAT report period with an upcoming due date.';
                }
                group(Control16)
                {
                    ShowCaption = false;
                    field("Manual Receive Period CU ID"; "Manual Receive Period CU ID")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Manual Receive Codeunit ID';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit ID associated with a manual receipt of the VAT return periods.';
                    }
                    field("Manual Receive Period CU Cap"; "Manual Receive Period CU Cap")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Manual Receive Codeunit Caption';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit caption associated with a manual receipt of the VAT return periods.';
                    }
                    field("Receive Submitted Return CU ID"; "Receive Submitted Return CU ID")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Receive Submitted Return Codeunit ID';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit ID associated with a receipt of the submitted VAT returns.';
                    }
                    field("Receive Submitted Return CUCap"; "Receive Submitted Return CUCap")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Receive Submitted Return Codeunit Caption';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit caption associated with a receipt of the submitted VAT returns.';
                    }
                }
                group("Auto Update Job")
                {
                    field("Update Period Job Frequency"; "Update Period Job Frequency")
                    {
                        ApplicationArea = VAT;
                        ToolTip = 'Specifies the job frequency for an automatic update of the VAT return periods.';
                    }
                    field("Auto Receive Period CU ID"; "Auto Receive Period CU ID")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Auto Receive Codeunit ID';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit ID associated with an automatic receipt of the VAT return periods. You can only edit this field if the Update Period Job Frequency field contains Never.';
                        Editable = "Update Period Job Frequency" = "Update Period Job Frequency"::Never;
                    }
                    field("Auto Receive Period CU Cap"; "Auto Receive Period CU Cap")
                    {
                        ApplicationArea = VAT;
                        Caption = 'Auto Receive Codeunit Caption';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit caption associated with an automatic receipt of the VAT return periods.';
                    }
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

