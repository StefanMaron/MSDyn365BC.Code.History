page 20018 "APIV1 - G/L Entries"
{
    APIVersion = 'v1.0';
    Caption = 'generalLedgerEntries', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'generalLedgerEntry';
    EntitySetName = 'generalLedgerEntries';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = "G/L Entry";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; "Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(postingDate; "Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'postingDate', Locked = true;
                }
                field(documentNumber; "Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'documentNumber', Locked = true;
                }
                field(documentType; "Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'documentType', Locked = true;
                }
                field(accountId; "Account Id")
                {
                    ApplicationArea = All;
                    Caption = 'accountId', Locked = true;
                }
                field(accountNumber; "G/L Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'accountNumber', Locked = true;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'description', Locked = true;
                }
                field(debitAmount; "Debit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'debitAmount', Locked = true;
                }
                field(creditAmount; "Credit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'creditAmount', Locked = true;
                }
                field(dimensions; DimensionsJSON)
                {
                    ApplicationArea = All;
                    Caption = 'dimensions', Locked = true;
                    ODataEDMType = 'Collection(DIMENSION)';
                    ToolTip = 'Specifies Journal Line Dimensions.';
                }
                field(lastModifiedDateTime; "Last Modified DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields();
    end;

    var
        DimensionsJSON: Text;

    local procedure SetCalculatedFields()
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        DimensionsJSON := GraphMgtComplexTypes.GetDimensionsJSON("Dimension Set ID");

    end;
}

