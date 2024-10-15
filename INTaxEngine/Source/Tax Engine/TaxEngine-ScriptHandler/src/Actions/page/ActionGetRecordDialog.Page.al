page 20167 "Action Get Record Dialog"
{
    Caption = 'Get Record';
    PageType = StandardDialog;
    DataCaptionExpression = FromTableName;
    PopulateAllFields = true;
    SourceTable = "Action Get Record";
    layout
    {
        area(Content)
        {
            group(Group)
            {
                field(GetRecordFromTableName; FromTableName)
                {
                    Caption = 'Table Name';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table name of Record variable.';
                    trigger OnValidate();
                    begin
                        AppObjectHelper.SearchObject(ObjectType::Table, "Table ID", FromTableName);
                    end;

                    trigger OnLookup(var Text: Text): Boolean;
                    begin
                        AppObjectHelper.OpenObjectLookup(ObjectType::Table, Text, "Table ID", FromTableName);
                    end;
                }
                field(Method; Method)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the method of getting the value from record variable like First,Last,Average etc.';
                }
                field("Table Filters"; TableFilters)
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table Filters';
                    ToolTip = 'Specifies the filters applied to record variable.';
                    trigger OnAssistEdit();
                    begin
                        if IsNullGuid("Table Filter ID") then
                            "Table Filter ID" := LookupEntityMgmt.CreateTableFilters("Case ID", "Script ID", "Table ID");

                        LookupDialogMgmt.OpenTableFilterDialog("Case ID", "Script ID", "Table Filter ID");

                        if not IsNullGuid("Table Filter ID") then
                            TableFilters := LookupSerialization.TableFilterToString("Case ID", "Script ID", Rec."Table Filter ID")
                    end;
                }
                field("Ignore if Record Not Found"; "Ignore If Record Not Found")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether error should be thrown in case record is not found.';
                }
                field(RecordVariable; RecordVariable2)
                {
                    Caption = 'Record Variable';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Variable name of Record.';
                    trigger OnValidate();
                    begin
                        ScriptSymbolsMgmt.SearchSymbolOfType(
                            "Symbol Type"::Variable,
                            "Symbol Data Type"::RECORD,
                            "Record Variable",
                            RecordVariable2);

                        Validate("Record Variable");
                    end;

                    trigger OnLookup(var Text: Text): Boolean;
                    begin
                        ScriptSymbolsMgmt.OpenSymbolsLookupOfType(
                            "Symbol Type"::Variable,
                            Text,
                            "Symbol Data Type"::RECORD,
                            "Record Variable",
                            RecordVariable2);

                        Validate("Record Variable");
                    end;
                }
            }
            part("Get Record Subform"; "Action Get Record Subform")
            {
                Caption = 'Set Variables';
                ApplicationArea = Basic, Suite;
                SubPageLink = "Script ID" = field("Script ID"), "Get Record ID" = field(ID), "Table ID" = field("Table ID");
                ShowFilter = false;
            }
        }
    }

    procedure SetCurrentRecord(var ActionGetRecord2: Record "Action Get Record");
    begin
        ActionGetRecord := ActionGetRecord2;

        TestRecord();

        FilterGroup := 2;
        SetRange("Case ID", ActionGetRecord."Case ID");
        SetRange("Script ID", ActionGetRecord."Script ID");
        SetRange(ID, ActionGetRecord.ID);
        FilterGroup := 0;

        ScriptSymbolsMgmt.SetContext(ActionGetRecord."Case ID", ActionGetRecord."Script ID");
    end;

    local procedure TestRecord();
    begin
        ActionGetRecord.TestField("Case ID");
        ActionGetRecord.TestField("Script ID");
        ActionGetRecord.TestField(ID);
    end;

    local procedure FormatLine();
    begin
        FromTableName := AppObjectHelper.GetObjectName(ObjectType::Table, "Table ID");
        if not IsNullGuid("Table Filter ID") then
            TableFilters := LookupSerialization.TableFilterToString(EmptyGuid, "Script ID", Rec."Table Filter ID");
        RecordVariable2 := ScriptSymbolsMgmt.GetSymbolName("Symbol Type"::Variable, "Record Variable");
    end;

    trigger OnOpenPage();
    begin
        TestRecord();
    end;

    trigger OnAfterGetRecord();
    begin
        FormatLine();
    end;

    trigger OnAfterGetCurrRecord();
    begin
        FormatLine();
    end;

    var
        ActionGetRecord: Record "Action Get Record";
        AppObjectHelper: Codeunit "App Object Helper";
        LookupEntityMgmt: Codeunit "Lookup Entity Mgmt.";
        LookupSerialization: Codeunit "Lookup Serialization";
        LookupDialogMgmt: Codeunit "Lookup Dialog Mgmt.";
        ScriptSymbolsMgmt: Codeunit "Script Symbols Mgmt.";
        FromTableName: Text[30];
        TableFilters: Text;
        RecordVariable2: Text[30];
        EmptyGuid: Guid;
}