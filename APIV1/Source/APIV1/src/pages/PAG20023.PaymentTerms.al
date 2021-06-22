page 20023 "APIV1 - Payment Terms"
{
    APIVersion = 'v1.0';
    Caption = 'paymentTerms', Locked = true;
    DelayedInsert = true;
    EntityName = 'paymentTerm';
    EntitySetName = 'paymentTerms';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = 3;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'code', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Code));
                    end;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Description));
                    end;
                }
                field(dueDateCalculation; "Due Date Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'dueDateCalculation', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Due Date Calculation"));
                    end;
                }
                field(discountDateCalculation; "Discount Date Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'discountDateCalculation', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Discount Date Calculation"));
                    end;
                }
                field(discountPercent; "Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'discountPercent', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Discount %"));
                    end;
                }
                field(calculateDiscountOnCreditMemos; "Calc. Pmt. Disc. on Cr. Memos")
                {
                    ApplicationArea = All;
                    Caption = 'calcPmtDiscOnCreditMemos', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Calc. Pmt. Disc. on Cr. Memos"));
                    end;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PaymentTerms: Record "Payment Terms";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        PaymentTerms.SETRANGE(Code, Code);
        IF NOT PaymentTerms.ISEMPTY() THEN
            INSERT();

        INSERT(TRUE);

        RecRef.GETTABLE(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CURRENTDATETIME());
        RecRef.SETTABLE(Rec);

        MODIFY(TRUE);
        EXIT(FALSE);
    end;

    trigger OnModifyRecord(): Boolean
    var
        PaymentTerms: Record "Payment Terms";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        IF xRec.Id <> Id THEN
            GraphMgtGeneralTools.ErrorIdImmutable();
        PaymentTerms.SETRANGE(Id, Id);
        PaymentTerms.FINDFIRST();

        IF Code = PaymentTerms.Code THEN
            MODIFY(TRUE)
        ELSE BEGIN
            PaymentTerms.TRANSFERFIELDS(Rec, FALSE);
            PaymentTerms.RENAME(Code);
            TRANSFERFIELDS(PaymentTerms, TRUE);
        END;
    end;

    var
        TempFieldSet: Record 2000000041 temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        IF TempFieldSet.GET(DATABASE::"Payment Terms", FieldNo) THEN
            EXIT;

        TempFieldSet.INIT();
        TempFieldSet.TableNo := DATABASE::"Payment Terms";
        TempFieldSet.VALIDATE("No.", FieldNo);
        TempFieldSet.INSERT(TRUE);
    end;
}






