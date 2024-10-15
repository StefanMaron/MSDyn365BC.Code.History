page 17247 "Tax Register Norm Groups"
{
    Caption = 'Norm Groups';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Register Norm Group";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code associated with the norm group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code description associated with the norm group.';
                }
                field("Has Details"; Rec."Has Details")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    HideValue = HasDetailsHideValue;
                    ToolTip = 'Specifies if the norm jurisdiction group has details.';
                }
                field("Search Detail"; Rec."Search Detail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the search detail associated with the norm group.';
                }
                field("Storing Method"; Rec."Storing Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the norm jurisdiction is calculated with a specific formula.';
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
            group("&Group")
            {
                Caption = '&Group';
                Image = Group;
                action(Details)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Details';
                    Image = ViewDetails;

                    trigger OnAction()
                    begin
                        ShowDetails();
                    end;
                }
                action("Template Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Template Setup';
                    Image = Setup;

                    trigger OnAction()
                    begin
                        SetupCalculationNorm();
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Calculate Details")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate Details';
                    Image = CalculateLines;
                    ToolTip = 'Create norm jurisdiction details. Norm details are used to define a constant tax rate for the norm.';

                    trigger OnAction()
                    begin
                        CalculateDetails();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Calculate Details_Promoted"; "Calculate Details")
                {
                }
                actionref(Details_Promoted; Details)
                {
                }
                actionref("Template Setup_Promoted"; "Template Setup")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        HasDetailsHideValue := false;
        HasDetailsOnFormat(Format("Has Details"));
    end;

    var
        Text1000: Label 'Nothing to calculate';
        Text1001: Label 'Present';
        [InDataSet]
        HasDetailsHideValue: Boolean;

    [Scope('OnPrem')]
    procedure CalculateDetails()
    var
        NormJurisdiction: Record "Tax Register Norm Jurisdiction";
        NormGroup: Record "Tax Register Norm Group";
    begin
        CurrPage.SaveRecord();
        Commit();
        NormGroup.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
        NormGroup.SetRange("Storing Method", "Storing Method"::Calculation);
        if not NormGroup.FindFirst() then
            Error(Text1000);
        NormJurisdiction.FilterGroup(2);
        NormJurisdiction.SetRange(Code, "Norm Jurisdiction Code");
        NormJurisdiction.FilterGroup(0);
        NormJurisdiction.SetRange(Code, "Norm Jurisdiction Code");
        REPORT.RunModal(REPORT::"Create Norm Details", true, true, NormJurisdiction);
    end;

    [Scope('OnPrem')]
    procedure ShowDetails()
    var
        NormDetail: Record "Tax Register Norm Detail";
    begin
        NormDetail.FilterGroup(2);
        NormDetail.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
        NormDetail.SetRange("Norm Group Code", Code);
        NormDetail.FilterGroup(0);
        if "Storing Method" = "Storing Method"::" " then
            PAGE.RunModal(0, NormDetail)
        else
            PAGE.RunModal(PAGE::"Tax Reg. Norm Details (Calc)", NormDetail);
    end;

    [Scope('OnPrem')]
    procedure SetupCalculationNorm()
    var
        NormTemplateLine: Record "Tax Reg. Norm Template Line";
    begin
        if "Storing Method" = "Storing Method"::" " then
            exit;
        NormTemplateLine.FilterGroup(2);
        NormTemplateLine.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
        NormTemplateLine.SetRange("Norm Group Code", Code);
        NormTemplateLine.FilterGroup(0);
        PAGE.Run(PAGE::"Tax Reg. Norm Template Setup", NormTemplateLine);
    end;

    local procedure HasDetailsOnFormat(Text: Text[1024])
    begin
        if "Has Details" then
            Text := Text1001
        else
            HasDetailsHideValue := true;
    end;
}

