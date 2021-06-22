page 20020 "APIV1 - Payment Methods"
{
    APIVersion = 'v1.0';
    Caption = 'paymentMethods', Locked = true;
    DelayedInsert = true;
    EntityName = 'paymentMethod';
    EntitySetName = 'paymentMethods';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = 289;
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
                    Caption = 'description', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Description));
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
        PaymentMethod: Record "Payment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        PaymentMethod.SETRANGE(Code, Code);
        IF NOT PaymentMethod.ISEMPTY() THEN
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
        PaymentMethod: Record "Payment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        IF xRec.Id <> Id THEN
            GraphMgtGeneralTools.ErrorIdImmutable();
        PaymentMethod.SETRANGE(Id, Id);
        PaymentMethod.FINDFIRST();

        IF Code = PaymentMethod.Code THEN
            MODIFY(TRUE)
        ELSE BEGIN
            PaymentMethod.TRANSFERFIELDS(Rec, FALSE);
            PaymentMethod.RENAME(Code);
            TRANSFERFIELDS(PaymentMethod);
        END;
    end;

    var
        TempFieldSet: Record 2000000041 temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        IF TempFieldSet.GET(DATABASE::"Payment Method", FieldNo) THEN
            EXIT;

        TempFieldSet.INIT();
        TempFieldSet.TableNo := DATABASE::"Payment Method";
        TempFieldSet.VALIDATE("No.", FieldNo);
        TempFieldSet.INSERT(TRUE);
    end;
}






