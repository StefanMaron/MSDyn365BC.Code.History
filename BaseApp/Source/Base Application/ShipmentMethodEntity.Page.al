page 5491 "Shipment Method Entity"
{
    Caption = 'shipmentMethods', Locked = true;
    DelayedInsert = true;
    EntityName = 'shipmentMethod';
    EntitySetName = 'shipmentMethods';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Shipment Method";

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
        ShipmentMethod: Record "Shipment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        ShipmentMethod.SetRange(Code, Code);
        if not ShipmentMethod.IsEmpty then
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
        ShipmentMethod: Record "Shipment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if xRec.Id <> Id then
            GraphMgtGeneralTools.ErrorIdImmutable;
        ShipmentMethod.SetRange(Id, Id);
        ShipmentMethod.FindFirst;

        if Code = ShipmentMethod.Code then
            Modify(true)
        else begin
            ShipmentMethod.TransferFields(Rec, false);
            ShipmentMethod.Rename(Code);
            TransferFields(ShipmentMethod, true);
        end;
    end;

    var
        TempFieldSet: Record "Field" temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::"Shipment Method", FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"Shipment Method";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

