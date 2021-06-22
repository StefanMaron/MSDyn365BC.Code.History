page 5492 "Item Categories Entity"
{
    Caption = 'itemCategories', Locked = true;
    DelayedInsert = true;
    EntityName = 'itemCategory';
    EntitySetName = 'itemCategories';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Item Category";

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
        ItemCategory: Record "Item Category";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        ItemCategory.SetRange(Code, Code);
        if not ItemCategory.IsEmpty then
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
        ItemCategory: Record "Item Category";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if xRec.Id <> Id then
            GraphMgtGeneralTools.ErrorIdImmutable;
        ItemCategory.SetRange(Id, Id);
        ItemCategory.FindFirst;

        if Code = ItemCategory.Code then
            Modify(true)
        else begin
            ItemCategory.TransferFields(Rec, false);
            ItemCategory.Rename(Code);
            TransferFields(ItemCategory);
        end;
    end;

    var
        TempFieldSet: Record "Field" temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::"Item Category", FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"Item Category";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

