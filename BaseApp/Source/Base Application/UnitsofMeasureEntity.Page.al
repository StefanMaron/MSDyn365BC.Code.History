page 5498 "Units of Measure Entity"
{
    Caption = 'unitsOfMeasure', Locked = true;
    DelayedInsert = true;
    EntityName = 'unitOfMeasure';
    EntitySetName = 'unitsOfMeasure';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Unit of Measure";

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
                field(internationalStandardCode; "International Standard Code")
                {
                    ApplicationArea = All;
                    Caption = 'InternationalStandardCode', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("International Standard Code"));
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

        exit(false);
    end;

    var
        TempFieldSet: Record "Field" temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::"Unit of Measure", FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"Unit of Measure";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

