#if not CLEAN19
page 31039 "Adv. Payment Selection - Purch"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Advance Payment Selection - Purchase (Obsolete)';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                OptionCaption = 'Adv.Paym. Letter,Adv.Paym. Invoice,Adv.Paym. Cr.Memo';
                ToolTip = 'Specifies type of cash desk report';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1220003)
            {
                ShowCaption = false;
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies sequence of cash desk report';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID of the report that the program will print.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the report.';
                }
                field("Use for Email Body"; Rec."Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that summarized information, such as invoice number, due date, and payment service link, will be inserted in the body of the email that you send.';
                }
                field("Use for Email Attachment"; Rec."Use for Email Attachment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related document will be attached to the email.';
                }
                field("Email Body Layout Code"; Rec."Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the email body layout that is used.';
                }
                field("Email Body Layout Description"; Rec."Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the email body layout that is used.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NewRecord();
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Option "P.Adv.Let","P.Adv.Inv","P.Adv.CrM";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Modify() then;
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"P.Adv.Let":
                SetRange(Usage, Usage::"P.Adv.Let");
            ReportUsage2::"P.Adv.Inv":
                SetRange(Usage, Usage::"P.Adv.Inv");
            ReportUsage2::"P.Adv.CrM":
                SetRange(Usage, Usage::"P.Adv.CrM");
        end;
        FilterGroup(0);
        CurrPage.Update();
    end;
}
#endif
