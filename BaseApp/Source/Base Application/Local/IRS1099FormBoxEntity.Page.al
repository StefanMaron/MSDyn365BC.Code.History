page 10900 "IRS 1099 Form-Box Entity"
{
    Caption = 'irs1099Codes', Locked = true;
    DelayedInsert = true;
    EntityName = 'irs1099Code';
    EntitySetName = 'irs1099Codes';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "IRS 1099 Form-Box";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
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
                field(minimumReportable; "Minimum Reportable")
                {
                    ApplicationArea = All;
                    Caption = 'MinimumReportable', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Minimum Reportable"));
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

    trigger OnModifyRecord(): Boolean
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.GetBySystemId(SystemId);

        if Code = IRS1099FormBox.Code then
            Modify(true)
        else begin
            IRS1099FormBox.TransferFields(Rec, false);
            IRS1099FormBox.Rename(Code);
            TransferFields(IRS1099FormBox);
        end;
    end;

    var
        TempFieldSet: Record "Field" temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::"IRS 1099 Form-Box", FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"IRS 1099 Form-Box";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

