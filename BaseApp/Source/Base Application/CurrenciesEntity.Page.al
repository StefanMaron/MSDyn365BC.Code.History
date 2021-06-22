page 5485 "Currencies Entity"
{
    Caption = 'currencies', Locked = true;
    DelayedInsert = true;
    EntityName = 'currency';
    EntitySetName = 'currencies';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = Currency;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Code));
                    end;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Description));
                    end;
                }
                field(symbol; Symbol)
                {
                    ApplicationArea = All;
                    Caption = 'Symbol', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Symbol));
                    end;
                }
                field(amountDecimalPlaces; "Amount Decimal Places")
                {
                    ApplicationArea = All;
                    Caption = 'AmountDecimalPlaces', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Amount Decimal Places"));
                    end;
                }
                field(amountRoundingPrecision; "Invoice Rounding Precision")
                {
                    ApplicationArea = All;
                    Caption = 'AmountRoundingPrecision', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Amount Rounding Precision"));
                    end;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        Insert(true);

        RecRef.GetTable(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CurrentDateTime);
        RecRef.SetTable(Rec);

        Modify(true);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Currency: Record Currency;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if xRec.Id <> Id then
            GraphMgtGeneralTools.ErrorIdImmutable;
        Currency.SetRange(Id, Id);
        Currency.FindFirst;

        if Code <> Currency.Code then begin
            Currency.TransferFields(Rec, false);
            Currency.Rename(Code);
            TransferFields(Currency);
        end;
    end;

    var
        TempFieldSet: Record "Field" temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::Currency, FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::Currency;
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

