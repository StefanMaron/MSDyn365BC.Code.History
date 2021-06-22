table 363 "Analysis View"
{
    Caption = 'Analysis View';
    DataCaptionFields = "Code", Name;
    LookupPageID = "Analysis View List";
    Permissions = TableData "Analysis View Entry" = rimd,
                  TableData "Analysis View Budget Entry" = rimd;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Account Source"; Option)
        {
            Caption = 'Account Source';
            OptionCaption = 'G/L Account,Cash Flow Account';
            OptionMembers = "G/L Account","Cash Flow Account";

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and ("Account Source" <> xRec."Account Source") then
                    ValidateDelete(FieldCaption("Account Source"));
                VerificationForCashFlow;
                AnalysisViewReset;
                "Account Filter" := '';
            end;
        }
        field(4; "Last Entry No."; Integer)
        {
            Caption = 'Last Entry No.';
        }
        field(5; "Last Budget Entry No."; Integer)
        {
            Caption = 'Last Budget Entry No.';
        }
        field(6; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
        }
        field(7; "Update on Posting"; Boolean)
        {
            Caption = 'Update on Posting';
            Editable = false;

            trigger OnValidate()
            begin
                VerificationForCashFlow;
            end;
        }
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if not Blocked and "Refresh When Unblocked" then begin
                    ValidateDelete(FieldCaption(Blocked));
                    AnalysisViewReset;
                    "Refresh When Unblocked" := false;
                end;
            end;
        }
        field(9; "Account Filter"; Code[250])
        {
            Caption = 'Account Filter';
            TableRelation = IF ("Account Source" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Account Source" = CONST("Cash Flow Account")) "Cash Flow Account";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                AnalysisViewEntry: Record "Analysis View Entry";
                AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
                GLAcc: Record "G/L Account";
                CFAccount: Record "Cash Flow Account";
            begin
                TestField(Blocked, false);
                if "Account Source" = "Account Source"::"G/L Account" then begin
                    if ("Last Entry No." <> 0) and (xRec."Account Filter" = '') and ("Account Filter" <> '')
                    then begin
                        ValidateModify(FieldCaption("Account Filter"));
                        GLAcc.SetFilter("No.", "Account Filter");
                        if GLAcc.Find('-') then
                            repeat
                                GLAcc.Mark := true;
                            until GLAcc.Next = 0;
                        GLAcc.SetRange("No.");
                        if GLAcc.Find('-') then
                            repeat
                                if not GLAcc.Mark then begin
                                    AnalysisViewEntry.SetRange("Analysis View Code", Code);
                                    AnalysisViewEntry.SetRange("Account No.", GLAcc."No.");
                                    AnalysisViewEntry.DeleteAll();
                                    AnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
                                    AnalysisViewBudgetEntry.SetRange("G/L Account No.", GLAcc."No.");
                                    AnalysisViewBudgetEntry.DeleteAll();
                                end;
                            until GLAcc.Next = 0;
                    end;
                    if ("Last Entry No." <> 0) and ("Account Filter" <> xRec."Account Filter") and (xRec."Account Filter" <> '')
                    then begin
                        ValidateDelete(FieldCaption("Account Filter"));
                        AnalysisViewReset;
                    end;
                end else begin
                    if ("Last Date Updated" <> 0D) and (xRec."Account Filter" = '') and ("Account Filter" <> '')
                    then begin
                        ValidateModify(FieldCaption("Account Filter"));
                        CFAccount.SetFilter("No.", "Account Filter");
                        if CFAccount.Find('-') then
                            repeat
                                CFAccount.Mark := true;
                            until CFAccount.Next = 0;
                        CFAccount.SetRange("No.");
                        if CFAccount.Find('-') then
                            repeat
                                if not CFAccount.Mark then begin
                                    AnalysisViewEntry.SetRange("Analysis View Code", Code);
                                    AnalysisViewEntry.SetRange("Account No.", CFAccount."No.");
                                    AnalysisViewEntry.DeleteAll();
                                end;
                            until CFAccount.Next = 0;
                    end;
                    if ("Last Date Updated" <> 0D) and ("Account Filter" <> xRec."Account Filter") and
                       (xRec."Account Filter" <> '')
                    then begin
                        ValidateDelete(FieldCaption("Account Filter"));
                        AnalysisViewReset;
                    end;
                end;
            end;
        }
        field(10; "Business Unit Filter"; Code[250])
        {
            Caption = 'Business Unit Filter';
            TableRelation = "Business Unit";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                BusUnit: Record "Business Unit";
                AnalysisViewEntry: Record "Analysis View Entry";
                AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
                TempBusUnit: Record "Business Unit" temporary;
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Business Unit Filter" = '') and
                   ("Business Unit Filter" <> xRec."Business Unit Filter")
                then begin
                    ValidateModify(FieldCaption("Business Unit Filter"));
                    if BusUnit.Find('-') then
                        repeat
                            TempBusUnit := BusUnit;
                            TempBusUnit.Insert();
                        until BusUnit.Next = 0;
                    TempBusUnit.Init();
                    TempBusUnit.Code := '';
                    TempBusUnit.Insert();
                    TempBusUnit.SetFilter(Code, "Business Unit Filter");
                    TempBusUnit.DeleteAll();
                    TempBusUnit.SetRange(Code);
                    if TempBusUnit.Find('-') then
                        repeat
                            AnalysisViewEntry.SetRange("Analysis View Code", Code);
                            AnalysisViewEntry.SetRange("Business Unit Code", TempBusUnit.Code);
                            AnalysisViewEntry.DeleteAll();
                            AnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
                            AnalysisViewBudgetEntry.SetRange("Business Unit Code", TempBusUnit.Code);
                            AnalysisViewBudgetEntry.DeleteAll();
                        until TempBusUnit.Next = 0
                end;
                if ("Last Entry No." <> 0) and (xRec."Business Unit Filter" <> '') and
                   ("Business Unit Filter" <> xRec."Business Unit Filter")
                then begin
                    ValidateDelete(FieldCaption("Business Unit Filter"));
                    AnalysisViewReset;
                end;
            end;
        }
        field(11; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if CheckIfLastEntryOrDateIsSet and ("Starting Date" <> xRec."Starting Date") then begin
                    ValidateDelete(FieldCaption("Starting Date"));
                    AnalysisViewReset;
                end;
            end;
        }
        field(12; "Date Compression"; Option)
        {
            Caption = 'Date Compression';
            InitValue = Day;
            OptionCaption = 'None,Day,Week,Month,Quarter,Year,Period';
            OptionMembers = "None",Day,Week,Month,Quarter,Year,Period;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if CheckIfLastEntryOrDateIsSet and ("Date Compression" <> xRec."Date Compression") then begin
                    ValidateDelete(FieldCaption("Date Compression"));
                    AnalysisViewReset;
                end;
            end;
        }
        field(13; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 1 Code", 13, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr);
                ModifyDim(FieldCaption("Dimension 1 Code"), "Dimension 1 Code", xRec."Dimension 1 Code");
                Modify;
            end;
        }
        field(14; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 2 Code", 14, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr);
                ModifyDim(FieldCaption("Dimension 2 Code"), "Dimension 2 Code", xRec."Dimension 2 Code");
                Modify;
            end;
        }
        field(15; "Dimension 3 Code"; Code[20])
        {
            Caption = 'Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 3 Code", 15, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr);
                ModifyDim(FieldCaption("Dimension 3 Code"), "Dimension 3 Code", xRec."Dimension 3 Code");
                Modify;
            end;
        }
        field(16; "Dimension 4 Code"; Code[20])
        {
            Caption = 'Dimension 4 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 4 Code", 16, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr);
                ModifyDim(FieldCaption("Dimension 4 Code"), "Dimension 4 Code", xRec."Dimension 4 Code");
                Modify;
            end;
        }
        field(17; "Include Budgets"; Boolean)
        {
            AccessByPermission = TableData "G/L Budget Name" = R;
            Caption = 'Include Budgets';

            trigger OnValidate()
            begin
                VerificationForCashFlow;

                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Include Budgets" = true) and ("Include Budgets" = false)
                then begin
                    ValidateDelete(FieldCaption("Include Budgets"));
                    AnalysisviewBudgetReset;
                end;
            end;
        }
        field(18; "Refresh When Unblocked"; Boolean)
        {
            Caption = 'Refresh When Unblocked';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Account Source")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AnalysisViewFilter: Record "Analysis View Filter";
    begin
        AnalysisViewReset;
        AnalysisViewFilter.SetRange("Analysis View Code", Code);
        AnalysisViewFilter.DeleteAll();
    end;

    var
        Text000: Label '%1\You cannot use the same dimension twice in the same analysis view.';
        Text001: Label 'The dimension %1 is used in the analysis view %2 %3.';
        Text002: Label ' You must therefore retain the dimension to keep consistency between the analysis view and the G/L entries.';
        Text004: Label 'All analysis views must be updated with the latest G/L entries and G/L budget entries.';
        Text005: Label ' Both blocked and unblocked analysis views must be updated.';
        Text007: Label ' Note, you must remove the checkmark in the blocked field before updating the blocked analysis views.\';
        Text008: Label 'Currently, %1 analysis views are not updated.';
        Text009: Label ' Do you wish to update these analysis views?';
        Text010: Label 'All analysis views must be updated with the latest G/L entries.';
        Text011: Label 'If you change the contents of the %1 field, the analysis view entries will be deleted.';
        Text012: Label '\You will have to update again.\\Do you want to enter a new value in the %1 field?';
        Text013: Label 'The update has been interrupted in response to the warning.';
        Text014: Label 'If you change the contents of the %1 field, the analysis view entries will be changed as well.\\';
        Text015: Label 'Do you want to enter a new value in the %1 field?';
        AnalysisViewEntry: Record "Analysis View Entry";
        NewAnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        NewAnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        Dim: Record Dimension;
        Text016: Label '%1 is not applicable for source type %2.';
        Text017Msg: Label 'Enabling the %1 feature immediately updates the analysis view with the latest entries. Do you want to start using the feature, and update the analysis view now?', Comment = '%1 = The name of the feature that is being enabled';	
        Text018Msg: Label 'If you enable the %1 feature it can take significantly more time to post documents, such as sales or purchase orders and invoices. Do you want to continue?', Comment = '%1 = The name of the feature that is being enabled';
        SkipConfirmationDialogue: Boolean;

    local procedure ModifyDim(DimFieldName: Text[100]; DimValue: Code[20]; xDimValue: Code[20])
    begin
        if CheckIfLastEntryOrDateIsSet and (DimValue <> xDimValue) then begin
            if DimValue <> '' then begin
                ValidateDelete(DimFieldName);
                AnalysisViewReset;
            end;
            if DimValue = '' then begin
                ValidateModify(DimFieldName);
                case DimFieldName of
                    FieldCaption("Dimension 1 Code"):
                        begin
                            AnalysisViewEntry.SetFilter("Dimension 1 Value Code", '<>%1', '');
                            if "Account Source" = "Account Source"::"G/L Account" then
                                AnalysisViewBudgetEntry.SetFilter("Dimension 1 Value Code", '<>%1', '');
                        end;
                    FieldCaption("Dimension 2 Code"):
                        begin
                            AnalysisViewEntry.SetFilter("Dimension 2 Value Code", '<>%1', '');
                            if "Account Source" = "Account Source"::"G/L Account" then
                                AnalysisViewBudgetEntry.SetFilter("Dimension 2 Value Code", '<>%1', '');
                        end;
                    FieldCaption("Dimension 3 Code"):
                        begin
                            AnalysisViewEntry.SetFilter("Dimension 3 Value Code", '<>%1', '');
                            if "Account Source" = "Account Source"::"G/L Account" then
                                AnalysisViewBudgetEntry.SetFilter("Dimension 3 Value Code", '<>%1', '');
                        end;
                    FieldCaption("Dimension 4 Code"):
                        begin
                            AnalysisViewEntry.SetFilter("Dimension 4 Value Code", '<>%1', '');
                            if "Account Source" = "Account Source"::"G/L Account" then
                                AnalysisViewBudgetEntry.SetFilter("Dimension 4 Value Code", '<>%1', '');
                        end;
                end;
                AnalysisViewEntry.SetRange("Analysis View Code", Code);
                if "Account Source" = "Account Source"::"G/L Account" then
                    AnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
                if AnalysisViewEntry.Find('-') then
                    repeat
                        AnalysisViewEntry.Delete();
                        NewAnalysisViewEntry := AnalysisViewEntry;
                        case DimFieldName of
                            FieldCaption("Dimension 1 Code"):
                                NewAnalysisViewEntry."Dimension 1 Value Code" := '';
                            FieldCaption("Dimension 2 Code"):
                                NewAnalysisViewEntry."Dimension 2 Value Code" := '';
                            FieldCaption("Dimension 3 Code"):
                                NewAnalysisViewEntry."Dimension 3 Value Code" := '';
                            FieldCaption("Dimension 4 Code"):
                                NewAnalysisViewEntry."Dimension 4 Value Code" := '';
                        end;
                        InsertAnalysisViewEntry;
                    until AnalysisViewEntry.Next = 0;
                if "Account Source" = "Account Source"::"G/L Account" then
                    if AnalysisViewBudgetEntry.Find('-') then
                        repeat
                            AnalysisViewBudgetEntry.Delete();
                            NewAnalysisViewBudgetEntry := AnalysisViewBudgetEntry;
                            case DimFieldName of
                                FieldCaption("Dimension 1 Code"):
                                    NewAnalysisViewBudgetEntry."Dimension 1 Value Code" := '';
                                FieldCaption("Dimension 2 Code"):
                                    NewAnalysisViewBudgetEntry."Dimension 2 Value Code" := '';
                                FieldCaption("Dimension 3 Code"):
                                    NewAnalysisViewBudgetEntry."Dimension 3 Value Code" := '';
                                FieldCaption("Dimension 4 Code"):
                                    NewAnalysisViewBudgetEntry."Dimension 4 Value Code" := '';
                            end;
                            InsertAnalysisViewBudgetEntry;
                        until AnalysisViewBudgetEntry.Next = 0;
            end;
        end;
    end;

    local procedure InsertAnalysisViewEntry()
    begin
        if not NewAnalysisViewEntry.Insert() then begin
            NewAnalysisViewEntry.Find;
            NewAnalysisViewEntry.Amount := NewAnalysisViewEntry.Amount + AnalysisViewEntry.Amount;
            if "Account Source" = "Account Source"::"G/L Account" then begin
                NewAnalysisViewEntry."Debit Amount" :=
                  NewAnalysisViewEntry."Debit Amount" + AnalysisViewEntry."Debit Amount";
                NewAnalysisViewEntry."Credit Amount" :=
                  NewAnalysisViewEntry."Credit Amount" + AnalysisViewEntry."Credit Amount";
                NewAnalysisViewEntry."Add.-Curr. Debit Amount" :=
                  NewAnalysisViewEntry."Add.-Curr. Debit Amount" + AnalysisViewEntry."Add.-Curr. Debit Amount";
                NewAnalysisViewEntry."Add.-Curr. Credit Amount" :=
                  NewAnalysisViewEntry."Add.-Curr. Credit Amount" + AnalysisViewEntry."Add.-Curr. Credit Amount";
            end;
            NewAnalysisViewEntry.Modify();
        end;
    end;

    local procedure InsertAnalysisViewBudgetEntry()
    begin
        if not NewAnalysisViewBudgetEntry.Insert() then begin
            NewAnalysisViewBudgetEntry.Find;
            NewAnalysisViewBudgetEntry.Amount := NewAnalysisViewBudgetEntry.Amount + AnalysisViewBudgetEntry.Amount;
            NewAnalysisViewBudgetEntry.Modify();
        end;
    end;

    procedure AnalysisViewReset()
    var
        AnalysisViewEntry: Record "Analysis View Entry";
    begin
        AnalysisViewEntry.SetRange("Analysis View Code", Code);
        AnalysisViewEntry.DeleteAll();
        "Last Entry No." := 0;
        "Last Date Updated" := 0D;
        AnalysisviewBudgetReset;

        OnAfterAnalysisViewReset(Rec);
    end;

    procedure CheckDimensionsAreRetained(ObjectType: Integer; ObjectID: Integer; OnlyIfIncludeBudgets: Boolean)
    begin
        Reset;
        if OnlyIfIncludeBudgets then
            SetRange("Include Budgets", true);
        if Find('-') then
            repeat
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 1 Code", Code, Name);
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 2 Code", Code, Name);
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 3 Code", Code, Name);
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 4 Code", Code, Name);
            until Next = 0;
    end;

    local procedure CheckDimIsRetained(ObjectType: Integer; ObjectID: Integer; DimCode: Code[20]; AnalysisViewCode: Code[10]; AnalysisViewName: Text[50])
    var
        SelectedDim: Record "Selected Dimension";
    begin
        if DimCode <> '' then
            if not SelectedDim.Get(UserId, ObjectType, ObjectID, '', DimCode) then
                Error(
                  Text001 +
                  Text002,
                  DimCode, AnalysisViewCode, AnalysisViewName);
    end;

    procedure CheckViewsAreUpdated()
    var
        GLEntry: Record "G/L Entry";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        NoNotUpdated: Integer;
        RunCheck: Boolean;
    begin
        if "Account Source" = "Account Source"::"G/L Account" then
            RunCheck := GLEntry.FindLast or GLBudgetEntry.FindLast
        else
            RunCheck := CFForecastEntry.FindLast;

        if RunCheck then begin
            NoNotUpdated := 0;
            Reset;
            if Find('-') then
                repeat
                    if ("Account Source" = "Account Source"::"Cash Flow Account") or
                       (("Last Entry No." < GLEntry."Entry No.") or
                        "Include Budgets" and ("Last Budget Entry No." < GLBudgetEntry."Entry No."))
                    then
                        NoNotUpdated := NoNotUpdated + 1;
                until Next = 0;
            if NoNotUpdated > 0 then
                if Confirm(
                     Text004 +
                     Text005 +
                     Text007 +
                     Text008 +
                     Text009, true, NoNotUpdated)
                then begin
                    if Find('-') then
                        repeat
                            if Blocked then begin
                                "Refresh When Unblocked" := true;
                                "Last Budget Entry No." := 0;
                                Modify;
                            end else
                                UpdateAnalysisView.Update(Rec, 2, true);
                        until Next = 0;
                end else
                    Error(Text010);
        end;
    end;

    procedure UpdateLastEntryNo()
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindLast then begin
            SetRange(Blocked, false);
            if Find('-') then
                repeat
                    "Last Entry No." := GLEntry."Entry No.";
                    Modify;
                until Next = 0;
            SetRange(Blocked);
        end;
    end;

    procedure ValidateDelete(FieldName: Text)
    var
        Question: Text;
    begin
        Question := StrSubstNo(
            Text011 +
            Text012, FieldName);
        if SkipConfirmationDialogue then
            exit;
        if not DIALOG.Confirm(Question, true) then
            Error(Text013);
    end;

    procedure AnalysisviewBudgetReset()
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
    begin
        AnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
        AnalysisViewBudgetEntry.DeleteAll();
        "Last Budget Entry No." := 0;
    end;

    local procedure ValidateModify(FieldName: Text)
    var
        Question: Text;
    begin
        Question := StrSubstNo(
            Text014 +
            Text015, FieldName);
        if SkipConfirmationDialogue then
            exit;
        if not DIALOG.Confirm(Question, true) then
            Error(Text013);
    end;

    procedure CopyAnalysisViewFilters(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10])
    var
        SelectedDim: Record "Selected Dimension";
        GLAcc: Record "G/L Account";
        CFAcc: Record "Cash Flow Account";
        BusUnit: Record "Business Unit";
        DimensionCode: Text[30];
    begin
        if Get(AnalysisViewCode) then begin
            if "Account Filter" <> '' then begin
                if "Account Source" = "Account Source"::"G/L Account" then
                    DimensionCode := GLAcc.TableCaption
                else
                    DimensionCode := CFAcc.TableCaption;

                if SelectedDim.Get(
                     UserId, ObjectType, ObjectID, AnalysisViewCode, DimensionCode)
                then begin
                    if SelectedDim."Dimension Value Filter" = '' then begin
                        SelectedDim."Dimension Value Filter" := "Account Filter";
                        SelectedDim.Modify();
                    end;
                end else begin
                    SelectedDim.Init();
                    SelectedDim."User ID" := UserId;
                    SelectedDim."Object Type" := ObjectType;
                    SelectedDim."Object ID" := ObjectID;
                    SelectedDim."Analysis View Code" := AnalysisViewCode;
                    SelectedDim."Dimension Code" := DimensionCode;
                    SelectedDim."Dimension Value Filter" := "Account Filter";
                    SelectedDim.Insert();
                end;
            end;
            if "Business Unit Filter" <> '' then
                if SelectedDim.Get(
                     UserId, ObjectType, ObjectID, AnalysisViewCode, BusUnit.TableCaption)
                then begin
                    if SelectedDim."Dimension Value Filter" = '' then begin
                        SelectedDim."Dimension Value Filter" := "Business Unit Filter";
                        SelectedDim.Modify();
                    end;
                end else begin
                    SelectedDim.Init();
                    SelectedDim."User ID" := UserId;
                    SelectedDim."Object Type" := ObjectType;
                    SelectedDim."Object ID" := ObjectID;
                    SelectedDim."Analysis View Code" := AnalysisViewCode;
                    SelectedDim."Dimension Code" := BusUnit.TableCaption;
                    SelectedDim."Dimension Value Filter" := "Business Unit Filter";
                    SelectedDim.Insert();
                end;
        end;
    end;

    local procedure VerificationForCashFlow()
    begin
        if "Account Source" <> "Account Source"::"Cash Flow Account" then
            exit;

        if "Include Budgets" then
            Error(Text016, FieldCaption("Include Budgets"), "Account Source");

        if "Update on Posting" then
            Error(Text016, FieldCaption("Update on Posting"), "Account Source");
    end;

    local procedure CheckIfLastEntryOrDateIsSet(): Boolean
    begin
        if "Account Source" = "Account Source"::"G/L Account" then
            exit("Last Entry No." <> 0);

        exit("Last Date Updated" <> 0D);
    end;

    procedure SetUpdateOnPosting(NewUpdateOnPosting: Boolean)
    begin
        if "Update on Posting" = NewUpdateOnPosting then
            exit;

        if not "Update on Posting" and NewUpdateOnPosting then begin
            if not Confirm(StrSubstNo(Text018Msg, FieldCaption("Update on Posting")), false) then
                exit;
            if not Confirm(StrSubstNo(Text017Msg, FieldCaption("Update on Posting")), false) then
                exit;
        end;

        "Update on Posting" := NewUpdateOnPosting;
        if "Update on Posting" then begin
            Modify;
            CODEUNIT.Run(CODEUNIT::"Update Analysis View", Rec);
            Find;
        end;
    end;

    procedure SetSkipConfirmationDialogue()
    begin
        SkipConfirmationDialogue := true;
    end;

    procedure RunAnalysisByDimensionPage()
    var
        AnalysisByDimParameters: Record "Analysis by Dim. Parameters" temporary;
    begin
        AnalysisByDimParameters."Analysis View Code" := Code;
        AnalysisByDimParameters.Insert();
        PAGE.RUN(PAGE::"Analysis by Dimensions", AnalysisByDimParameters);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAnalysisViewReset(var AnalysisView: Record "Analysis View")
    begin
    end;
}

