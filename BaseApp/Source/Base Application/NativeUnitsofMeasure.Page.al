page 2860 "Native - Units of Measure"
{
    Caption = 'nativeInvoicingUnitsOfMeasure', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = Id;
    PageType = List;
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
                    Caption = 'id', Locked = true;
                }
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'code', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Code));
                    end;
                }
                field(displayName; DescriptionInCurrentLanguage)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                    ToolTip = 'Specifies the displayName.';

                    trigger OnValidate()
                    begin
                        if DescriptionInCurrentLanguage <> GetDescriptionInCurrentLanguage then begin
                            Validate(Description, CopyStr(DescriptionInCurrentLanguage, 1, MaxStrLen(Description)));
                            RegisterFieldSet(FieldNo(Description));
                        end;
                    end;
                }
                field(internationalStandardCode; "International Standard Code")
                {
                    ApplicationArea = All;
                    Caption = 'internationalStandardCode', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("International Standard Code"));
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

    trigger OnAfterGetRecord()
    begin
        DescriptionInCurrentLanguage := GetDescriptionInCurrentLanguage;
    end;

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

    trigger OnOpenPage()
    begin
        BindSubscription(NativeAPILanguageHandler);
    end;

    var
        TempFieldSet: Record "Field" temporary;
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        DescriptionInCurrentLanguage: Text;

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

