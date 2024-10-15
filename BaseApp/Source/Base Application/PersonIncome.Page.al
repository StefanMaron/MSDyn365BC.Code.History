page 17495 "Person Income"
{
    Caption = 'Person Income';
    PageType = Document;
    SourceTable = "Person Income Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Person No."; "Person No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Total Taxable Income"; "Total Taxable Income")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Total Tax Deductions"; "Total Tax Deductions")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Total Annual Tax Deductions"; "Total Annual Tax Deductions")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Total Accrued Tax"; "Total Accrued Tax")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Total Accrued Tax 13%"; "Total Accrued Tax 13%")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Total Accrued Tax 30%"; "Total Accrued Tax 30%")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Total Accrued Tax 35%"; "Total Accrued Tax 35%")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Total Accrued Tax 9%"; "Total Accrued Tax 9%")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Total Paid to Budget"; "Total Paid to Budget")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Total Paid to Person"; "Total Paid to Person")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
            }
            part(Lines; "Person Income Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Control1902597601)
            {
                Caption = 'Document';
                field("Total Income (Doc)"; "Total Income (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Taxable Income (Doc)"; "Taxable Income (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Accrued (Doc)"; "Income Tax Accrued (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Paid (Doc)"; "Income Tax Paid (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Return LY (Doc)"; "Income Tax Return LY (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Return Settled LY (Doc)"; "Tax Return Settled LY (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Return Paid LY (Doc)"; "Tax Return Paid LY (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Due (Doc)"; "Income Tax Due (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Overpaid (Doc)"; "Income Tax Overpaid (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax for Withdraw. (Doc)"; "Income Tax for Withdraw. (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Document)
            {
                Caption = 'Document';
                Image = Document;
                action("Tax Deductions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax Deductions';
                    Image = TaxPayment;
                    RunObject = Page "Person Tax Deductions";
                    RunPageLink = "Document No." = FIELD("No.");
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Recalculate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recalculate';
                    Image = Recalculate;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';

                    trigger OnAction()
                    begin
                        Recalculate;
                    end;
                }
                separator(Action1210012)
                {
                }
                group("2-NDFL")
                {
                    Caption = '2-NDFL';
                    Image = "Action";
                    action("Export to Excel")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export to Excel';
                        Image = ExportToExcel;
                        ToolTip = 'Export the data to Excel.';

                        trigger OnAction()
                        var
                            PersonIncomeHeader: Record "Person Income Header";
                        begin
                            PersonIncomeHeader.SetRange("No.", "No.");
                            REPORT.RunModal(REPORT::"Form 2-NDFL", true, false, PersonIncomeHeader)
                        end;
                    }
                    action("Export to XML")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export to XML';
                        Image = Export;
                        ToolTip = 'Export the data to an XML file.';

                        trigger OnAction()
                        var
                            PersonIncomeHeader: Record "Person Income Header";
                        begin
                            PersonIncomeHeader.SetRange("No.", "No.");
                            REPORT.RunModal(REPORT::"Export Form 2-NDFL to XML", true, false, PersonIncomeHeader)
                        end;
                    }
                }
                group("1-NDFL")
                {
                    Caption = '1-NDFL';
                    Image = "Action";
                    action(Action1210017)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export to Excel';
                        Image = ExportToExcel;
                        ToolTip = 'Export the data to Excel.';

                        trigger OnAction()
                        var
                            PersonIncomeHeader: Record "Person Income Header";
                        begin
                            PersonIncomeHeader.SetRange("No.", "No.");
                            REPORT.RunModal(REPORT::"Form 1-NDFL", true, false, PersonIncomeHeader)
                        end;
                    }
                }
            }
        }
    }
}

