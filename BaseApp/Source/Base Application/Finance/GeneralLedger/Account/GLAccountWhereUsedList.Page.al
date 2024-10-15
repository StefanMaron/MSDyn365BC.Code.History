namespace Microsoft.Finance.GeneralLedger.Account;

page 99 "G/L Account Where-Used List"
{
    Caption = 'G/L Account Where-Used List';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    PageType = List;
    SourceTable = "G/L Account Where-Used";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object number of the setup table where the G/L account is used.';
                    Visible = false;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Table Name of the setup table where the G/L account is used.';
                }
                field(Line; Rec.Line)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a reference to Line in the setup table, where the G/L account is used. For example, the reference could be a posting group code.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the field in the setup table where the G/L account is used.';
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
        area(processing)
        {
            action(ShowDetails)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show Details';
                Image = ViewDetails;
                ToolTip = 'View more details on the selected record.';

                trigger OnAction()
                var
                    CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
                begin
                    Clear(CalcGLAccWhereUsed);
                    CalcGLAccWhereUsed.ShowSetupForm(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowDetails_Promoted; ShowDetails)
                {
                }
            }
        }
    }
}

