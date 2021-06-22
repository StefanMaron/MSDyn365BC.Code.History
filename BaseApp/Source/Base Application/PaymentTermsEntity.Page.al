page 5490 "Payment Terms Entity"
{
    Caption = 'paymentTerms', Locked = true;
    DelayedInsert = true;
    EntityName = 'paymentTerm';
    EntitySetName = 'paymentTerms';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Payment Terms";

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
                    Caption = 'DisplayName', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Description));
                    end;
                }
                field(dueDateCalculation; "Due Date Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'DueDateCalculation', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Due Date Calculation"));
                    end;
                }
                field(discountDateCalculation; "Discount Date Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'DiscountDateCalculation', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Discount Date Calculation"));
                    end;
                }
                field(discountPercent; "Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'DiscountPercent', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Discount %"));
                    end;
                }
                field(calculateDiscountOnCreditMemos; "Calc. Pmt. Disc. on Cr. Memos")
                {
                    ApplicationArea = All;
                    Caption = 'CalcPmtDiscOnCreditMemos', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Calc. Pmt. Disc. on Cr. Memos"));
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
        PaymentTerms: Record "Payment Terms";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        PaymentTerms.SetRange(Code, Code);
        if not PaymentTerms.IsEmpty then
            Insert;

        Insert(true);

        RecRef.GetTable(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CurrentDateTime);
        RecRef.SetTable(Rec);

        Modify(true);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        PaymentTerms: Record "Payment Terms";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if xRec.Id <> Id then
            GraphMgtGeneralTools.ErrorIdImmutable;
        PaymentTerms.SetRange(Id, Id);
        PaymentTerms.FindFirst;

        if Code = PaymentTerms.Code then
            Modify(true)
        else begin
            PaymentTerms.TransferFields(Rec, false);
            PaymentTerms.Rename(Code);
            TransferFields(PaymentTerms, true);
        end;
    end;

    var
        TempFieldSet: Record "Field" temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::"Payment Terms", FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"Payment Terms";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

