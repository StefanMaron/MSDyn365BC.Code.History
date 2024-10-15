page 12491 "Organizational Units"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Departments';
    CardPageID = "Organizational Unit Card";
    Editable = false;
    PageType = List;
    SourceTable = "Organizational Unit";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = CodeEmphasize;
                    ToolTip = 'Specifies the code associated with the organizational unit.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name associated with the organizational unit.';
                }
                field("Parent Code"; "Parent Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Purpose; Purpose)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field(Totalling; Totalling)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Manager No."; "Manager No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Address Code"; "Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the address.';
                }
                field("Isolated Org. Unit"; "Isolated Org. Unit")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Timesheet Owner"; "Timesheet Owner")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Total Position Rate"; "Total Position Rate")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Filled Position Rate"; "Filled Position Rate")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Or&g. Unit")
            {
                Caption = 'Or&g. Unit';
                separator(Action1210039)
                {
                }
                action("Default Contract Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Contract Terms';
                    Image = EmployeeAgreement;
                    RunObject = Page "Default Labor Contract Terms";
                    RunPageLink = "Org. Unit Code" = FIELD(Code);
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Approve)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve';
                    Image = Approve;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        Approve(false);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    begin
                        Reopen(false);
                    end;
                }
                action(Close)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Close';
                    Image = Close;

                    trigger OnAction()
                    begin
                        Close(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        CodeOnFormat;
        NameOnFormat;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;

    var
        [InDataSet]
        CodeEmphasize: Boolean;
        [InDataSet]
        NameEmphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;

    [Scope('OnPrem')]
    procedure GetSelectionFilter(): Text
    var
        OrganizationalUnit: Record "Organizational Unit";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(OrganizationalUnit);
        exit(SelectionFilterManagement.GetSelectionFilterForOrgUnit(OrganizationalUnit));
    end;

    [Scope('OnPrem')]
    procedure SetSelection(var OrganizationalUnit: Record "Organizational Unit")
    begin
        CurrPage.SetSelectionFilter(OrganizationalUnit);
    end;

    local procedure CodeOnFormat()
    begin
        CodeEmphasize := Type = Type::Heading;
    end;

    local procedure NameOnFormat()
    begin
        NameIndent := Level;
        NameEmphasize := Type = Type::Heading;
    end;
}

