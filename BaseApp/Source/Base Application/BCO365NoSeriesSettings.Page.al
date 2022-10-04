#if not CLEAN21
page 2339 "BC O365 No. Series Settings"
{
    Caption = ' ';
    PageType = CardPart;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control2)
            {
                InstructionalText = 'If you have already sent invoices, please consult your accountant before you change the number sequence.';
                ShowCaption = false;
            }
            group(Control8)
            {
                ShowCaption = false;
                field(NextInvoiceNo; NextInvoiceNo)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Next invoice number';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number that your next sent invoice will get.';

                    trigger OnAssistEdit()
                    var
                        NoSeries: Record "No. Series";
                    begin
                        if SalesReceivablesSetup."Posted Invoice Nos." <> '' then begin
                            if NoSeries.Get(SalesReceivablesSetup."Posted Invoice Nos.") then;
                            PAGE.RunModal(PAGE::"BC O365 No. Series Card", NoSeries);
                            NextInvoiceNo := NoSeriesManagement.ClearStateAndGetNextNo(SalesReceivablesSetup."Posted Invoice Nos.");
                            CurrPage.Update();
                        end;
                    end;
                }
            }
            group(Control6)
            {
                ShowCaption = false;
                field(NextEstimateNo; NextEstimateNo)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Next estimate number';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number that your next estimate will get.';

                    trigger OnAssistEdit()
                    var
                        NoSeries: Record "No. Series";
                    begin
                        if SalesReceivablesSetup."Quote Nos." <> '' then begin
                            if NoSeries.Get(SalesReceivablesSetup."Quote Nos.") then;
                            PAGE.RunModal(PAGE::"BC O365 No. Series Card", NoSeries);
                            NextEstimateNo := NoSeriesManagement.ClearStateAndGetNextNo(SalesReceivablesSetup."Quote Nos.");
                            CurrPage.Update();
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Initialize();
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NextInvoiceNo: Code[20];
        NextEstimateNo: Code[20];

    local procedure Initialize()
    begin
        if not SalesReceivablesSetup.Get() then
            exit;

        if SalesReceivablesSetup."Posted Invoice Nos." <> '' then
            NextInvoiceNo := NoSeriesManagement.ClearStateAndGetNextNo(SalesReceivablesSetup."Posted Invoice Nos.");
        if SalesReceivablesSetup."Quote Nos." <> '' then
            NextEstimateNo := NoSeriesManagement.ClearStateAndGetNextNo(SalesReceivablesSetup."Quote Nos.");
    end;
}
#endif
