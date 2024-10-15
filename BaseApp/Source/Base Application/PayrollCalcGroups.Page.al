page 17403 "Payroll Calc Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Calc Groups';
    PageType = List;
    SourceTable = "Payroll Calc Group";
    UsageCategory = Lists;

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
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Disabled Persons"; "Disabled Persons")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Payroll Calc Type")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payroll Calc Type';
                Image = CalculateVAT;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Payroll Calc Group Lines";
                RunPageLink = "Payroll Calc Group" = FIELD(Code);
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Ellipsis = true;
                    Image = Export;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(PayrollCalcGroup);
                        PayrollDataExchangeMgt.ExportPayrollCalcGroups(PayrollCalcGroup);
                    end;
                }
            }
        }
    }

    var
        PayrollCalcGroup: Record "Payroll Calc Group";
        PayrollDataExchangeMgt: Codeunit "Payroll Data Exchange Mgt.";
}

