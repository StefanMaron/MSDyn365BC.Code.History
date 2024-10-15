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
                field("EC Sales List No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("VAT Return No. Series"; "VAT Return No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series that is used for VAT return records.';
                }
                field("VAT Return Period No. Series"; "VAT Return Period No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series that is used for the VAT return period records.';
                }
            }
            group("Return Period")
            {
                Caption = 'Return Period';
                field("Report Version"; "Report Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT report version that is used for the VAT reporting periods.';
                }
                field("Period Reminder Calculation"; "Period Reminder Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that is used to notify about an open VAT report period with an upcoming due date.';
                }
                group(Control16)
                {
                    ShowCaption = false;
                    field("Manual Receive Period CU ID"; "Manual Receive Period CU ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Manual Receive Codeunit ID';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit ID associated with a manual receipt of the VAT return periods.';
                    }
                    field("Manual Receive Period CU Cap"; "Manual Receive Period CU Cap")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Manual Receive Codeunit Caption';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit caption associated with a manual receipt of the VAT return periods.';
                    }
                    field("Receive Submitted Return CU ID"; "Receive Submitted Return CU ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receive Submitted Return Codeunit ID';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit ID associated with a receipt of the submitted VAT returns.';
                    }
                    field("Receive Submitted Return CUCap"; "Receive Submitted Return CUCap")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receive Submitted Return Codeunit Caption';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit caption associated with a receipt of the submitted VAT returns.';
                    }
                }
                group("Auto Update Job")
                {
                    Caption = 'Auto Update Job';
                    field("Update Period Job Frequency"; "Update Period Job Frequency")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the job frequency for an automatic update of the VAT return periods.';
                    }
                    field("Auto Receive Period CU ID"; "Auto Receive Period CU ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Auto Receive Codeunit ID';
                        Importance = Additional;
                        ToolTip = 'Specifies the codeunit ID associated with an automatic receipt of the VAT return periods. You can only edit this field if the Update Period Job Frequency field contains Never.';
                        Editable = "Update Period Job Frequency" = "Update Period Job Frequency"::Never;
                    }
                    field("Auto Receive Period CU Cap"; "Auto Receive Period CU Cap")
                    {
                        ApplicationArea = Basic, Suite;
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

