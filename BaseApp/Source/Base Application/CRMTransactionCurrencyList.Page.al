page 5345 "CRM TransactionCurrency List"
{
    ApplicationArea = Suite;
    Caption = 'Transaction Currencies - Common Data Service';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Transactioncurrency";
    SourceTableView = SORTING(ISOCurrencyCode);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(ISOCurrencyCode; ISOCurrencyCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'ISO Currency Code';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies the ISO currency code, which is required in Common Data Service.';
                }
                field(CurrencyName; CurrencyName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Name';
                    ToolTip = 'Specifies the name of the currency.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Common Data Service record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(TransactionCurrencyId, DATABASE::Currency, RecordID) then
            if CurrentlyCoupledCRMTransactioncurrency.TransactionCurrencyId = TransactionCurrencyId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
        end;
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");

        FilterGroup(4);
        SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Transactioncurrency"));
        FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMTransactioncurrency: Record "CRM Transactioncurrency";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMTransactioncurrency(CRMTransactioncurrency: Record "CRM Transactioncurrency")
    begin
        CurrentlyCoupledCRMTransactioncurrency := CRMTransactioncurrency;
    end;
}

