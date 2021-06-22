page 5494 "Country/Regions Entity"
{
    Caption = 'countriesRegions', Locked = true;
    DelayedInsert = true;
    EntityName = 'countryRegion';
    EntitySetName = 'countriesRegions';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Country/Region";

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
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Name));
                    end;
                }
                field(addressFormat; "Address Format")
                {
                    ApplicationArea = All;
                    Caption = 'AddressFormat', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Address Format"));
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
        CountryRegion: Record "Country/Region";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        CountryRegion.SetRange(Code, Code);
        if not CountryRegion.IsEmpty then
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
        CountryRegion: Record "Country/Region";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if xRec.Id <> Id then
            GraphMgtGeneralTools.ErrorIdImmutable;
        CountryRegion.SetRange(Id, Id);
        CountryRegion.FindFirst;

        if Code = CountryRegion.Code then
            Modify(true)
        else begin
            CountryRegion.TransferFields(Rec, false);
            CountryRegion.Rename(Code);
            TransferFields(CountryRegion);
        end;
    end;

    var
        TempFieldSet: Record "Field" temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::"Country/Region", FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"Country/Region";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

