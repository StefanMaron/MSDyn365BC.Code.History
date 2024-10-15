namespace Microsoft.Finance.RoleCenters;
using Microsoft.RoleCenters;
using System.Visualization;
using Microsoft.Sales.Receivables;

page 1318 "Account Receivables KPIs"
{
    PageType = CardPart;
    Caption = 'Accounts Receivables Overview';
    SourceTable = "Finance Cue";

    layout
    {
        area(Content)
        {
            cuegroup(KPIs)
            {
                ShowCaption = false;
                CuegroupLayout = Wide;
                field("Sales - Total Overdue (LCY)"; Rec."Total Overdue (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total overdue amount.';
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        CustLedgerEntry.SetRange(Open, true);
                        CustLedgerEntry.SetFilter("Remaining Amount", '>%1', 0);
                        CustLedgerEntry.SetFilter("Due Date", '<=%1', WorkDate());
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
                field("Sales - Total Outstanding (LCY)"; Rec."Total Outstanding (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total outstanding amount.';
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        CustLedgerEntry.SetRange(Open, true);
                        CustLedgerEntry.SetFilter("Remaining Amount", '>%1', 0);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
                field("A/R Accounts Balance"; Rec."AR Accounts Balance")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sum of the accounts that have the account receivables account category. You can configure which account category is considered for Account Receivables in the General Ledger Setup page.';

                    trigger OnDrillDown()
                    begin
                        ActivitiesMgt.DrillDownCalcARAccountsBalances();
                    end;
                }
                field("Average Collection Days"; AverageCollectionDays)
                {
                    ApplicationArea = All;
                    Caption = 'Average Collection Days';
                    ToolTip = 'Specifies how long customers took to pay invoices in the last three months. This is the average number of days from when invoices are issued to when customers pay the invoices.';
                }
                field("Sales Invoices Due Next Week"; ActivitiesCue."Sales Invoices Due Next Week")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Invoices Due Next Week';
                    ToolTip = 'Specifies the total amount of sales invoices due next week.';
                    StyleExpr = SalesInvoicesDueNextWeekStyleExpr;

                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        CustLedgerEntry.SetFilter("Document Type", '%1|%2', CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::"Credit Memo");
                        CustLedgerEntry.SetFilter("Due Date", '%1..%2', CalcDate('<1D>', Today), CalcDate('<1W>', Today));
                        CustLedgerEntry.SetRange("Open", true);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
            }
        }
    }

    var
        ActivitiesCue: Record "Activities Cue";
        ActivitiesMgt: Codeunit "Activities Mgt.";
        SalesInvoicesDueNextWeekStyleExpr: Text;
        AverageCollectionDays: Decimal;

    trigger OnInit()
    var
        CuesAndKPIs: Codeunit "Cues And KPIs";
        SalesInvoicesDueNextWeekStyle: Enum "Cues And KPIs Style";
    begin
        Rec.SetRange("Overdue Date Filter", 0D, WorkDate());
        if not Rec.Get() then begin
            Clear(Rec);
            Rec.Insert();
        end;
        if not ActivitiesCue.Get() then begin
            ActivitiesCue.Init();
            ActivitiesCue.Insert();
            Commit();
        end;
        ActivitiesCue.SetFilter("Due Next Week Filter", '%1..%2', CalcDate('<1D>', Today), CalcDate('<1W>', Today));
        ActivitiesCue.CalcFields("Sales Invoices Due Next Week");
        CuesAndKPIs.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Sales Invoices Due Next Week"), ActivitiesCue."Sales Invoices Due Next Week", SalesInvoicesDueNextWeekStyle);
        SalesInvoicesDueNextWeekStyleExpr := Format(SalesInvoicesDueNextWeekStyle);
        Rec."AR Accounts Balance" := ActivitiesMgt.CalcARAccountsBalances();
        Rec.Modify();
    end;

    trigger OnOpenPage()
    begin
        AverageCollectionDays := ActivitiesMgt.CalcAverageCollectionDays();
    end;
}