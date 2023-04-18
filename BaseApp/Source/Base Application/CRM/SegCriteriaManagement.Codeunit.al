codeunit 5062 SegCriteriaManagement
{

    trigger OnRun()
    begin
    end;

    procedure InsertContact(SegmentNo: Code[20]; ContactNo: Code[20])
    var
        Cont: Record Contact;
    begin
        Cont.SetRange("No.", ContactNo);

        InsertCriteriaAction(SegmentNo, REPORT::"Add Contacts", false, false, false, false, false);
        InsertCriteriaFilters(SegmentNo, DATABASE::Contact, Cont.GetFilters, Cont.GetView(false));
    end;

    procedure DeleteContact(SegmentNo: Code[20]; ContactNo: Code[20])
    var
        Cont: Record Contact;
    begin
        Cont.SetRange("No.", ContactNo);

        InsertCriteriaAction(SegmentNo, REPORT::"Remove Contacts - Reduce", false, false, false, false, false);
        InsertCriteriaFilters(SegmentNo, DATABASE::Contact, Cont.GetFilters, Cont.GetView(false));
    end;

    procedure InsertReuseLogged(SegmentNo: Code[20]; LoggedSegmentEntryNo: Integer)
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        InteractLogEntry.SetCurrentKey("Logged Segment Entry No.");
        InteractLogEntry.SetRange("Logged Segment Entry No.", LoggedSegmentEntryNo);

        InsertCriteriaAction(SegmentNo, REPORT::"Add Contacts", true, false, false, false, false);
        InsertCriteriaFilters(
          SegmentNo, DATABASE::"Interaction Log Entry", InteractLogEntry.GetFilters, InteractLogEntry.GetView(false));
    end;

    procedure InsertCriteriaAction(SegmentNo: Code[20]; CalledFromReportNo: Integer; AllowExistingContacts: Boolean; ExpandContact: Boolean; AllowCompanyWithPersons: Boolean; IgnoreExclusion: Boolean; EntireCompanies: Boolean)
    var
        SegCriteriaLine: Record "Segment Criteria Line";
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertCriteriaAction(
          SegmentNo, CalledFromReportNo, AllowExistingContacts, ExpandContact, AllowCompanyWithPersons, IgnoreExclusion, EntireCompanies,
          IsHandled);
        if IsHandled then
            exit;

        SegCriteriaLine.LockTable();
        SegCriteriaLine.SetRange("Segment No.", SegmentNo);
        if SegCriteriaLine.FindLast() then
            NextLineNo := SegCriteriaLine."Line No." + 1
        else
            NextLineNo := 1;

        SegCriteriaLine.Init();
        SegCriteriaLine."Segment No." := SegmentNo;
        SegCriteriaLine."Line No." := NextLineNo;
        SegCriteriaLine.Type := SegCriteriaLine.Type::Action;
        case CalledFromReportNo of
            REPORT::"Add Contacts":
                SegCriteriaLine.Action := SegCriteriaLine.Action::"Add Contacts";
            REPORT::"Remove Contacts - Reduce":
                SegCriteriaLine.Action := SegCriteriaLine.Action::"Remove Contacts (Reduce)";
            REPORT::"Remove Contacts - Refine":
                SegCriteriaLine.Action := SegCriteriaLine.Action::"Remove Contacts (Refine)";
            else
                OnInsertCriteriaActionOnCalledFromReportNoElseCase(SegCriteriaLine, CalledFromReportNo);
        end;
        SegCriteriaLine."Allow Existing Contacts" := AllowExistingContacts;
        SegCriteriaLine."Expand Contact" := ExpandContact;
        SegCriteriaLine."Allow Company with Persons" := AllowCompanyWithPersons;
        SegCriteriaLine."Ignore Exclusion" := IgnoreExclusion;
        SegCriteriaLine."Entire Companies" := EntireCompanies;
        OnBeforeInsertCriteriaActionOnBeforeSegCriteriaLineInsert(SegCriteriaLine);
        SegCriteriaLine.Insert();
    end;

    procedure InsertCriteriaFilters(SegmentNo: Code[20]; TableNo: Integer; TableFilter: Text; TableView: Text)
    var
        SegCriteriaLine: Record "Segment Criteria Line";
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertSegmentCriteriaFilter(SegmentNo, TableNo, TableFilter, TableView, IsHandled);
        if IsHandled then
            exit;

        if TableFilter = '' then
            exit;

        SegCriteriaLine.SetRange("Segment No.", SegmentNo);
        if SegCriteriaLine.FindLast() then
            NextLineNo := SegCriteriaLine."Line No." + 1
        else
            NextLineNo := 1;

        SegCriteriaLine.Init();
        SegCriteriaLine."Segment No." := SegmentNo;
        SegCriteriaLine."Line No." := NextLineNo;
        SegCriteriaLine.Type := SegCriteriaLine.Type::Filter;
        SegCriteriaLine."Table No." := TableNo;
        SegCriteriaLine."Table View" := TableView;
#if not CLEAN22
        SegCriteriaLine.View := CopyStr(TableView, 1, MaxStrLen(SegCriteriaLine.View));
#endif
        OnBeforeInsertCriteriaFilterOnBeforeSegCriteriaLineInsert(SegCriteriaLine);
        SegCriteriaLine.Insert();

        SegCriteriaLine.Reset();
        SegCriteriaLine.SetCurrentKey("Segment No.", Type);
        SegCriteriaLine.SetRange("Segment No.", SegmentNo);
        SegCriteriaLine.SetRange(Type, SegCriteriaLine.Type::Action);
        SegCriteriaLine.FindLast();
        SegCriteriaLine."No. of Filters" := SegCriteriaLine."No. of Filters" + 1;
        OnBeforeInsertCriteriaFilterOnBeforeSegCriteriaLineModify(SegCriteriaLine);
        SegCriteriaLine.Modify();
    end;

#if not CLEAN22
    [Obsolete('Replaced by procedure InsertCriteriaFilters()', '22.0')]
    procedure InsertCriteriaFilter(SegmentNo: Code[20]; TableNo: Integer; "Filter": Text[250]; View: Text[250])
    begin
        InsertCriteriaFilters(SegmentNo, TableNo, Filter, View);
    end;
#endif

    procedure GetSegCriteriaFilters(TableNo: Integer; TableView: Text): Text
    var
        ContProfileAnswer: Record "Contact Profile Answer";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        RecRef: RecordRef;
        TableFilters: Text;
    begin
        case TableNo of
            DATABASE::Contact,
            DATABASE::"Contact Mailing Group",
            DATABASE::"Interaction Log Entry",
            DATABASE::"Contact Job Responsibility",
            DATABASE::"Contact Industry Group",
            DATABASE::"Contact Business Relation",
            DATABASE::"Value Entry":
                begin
                    RecRef.Open(TableNo);
                    RecRef.SetView(TableView);
                    exit(RecRef.GetFilters());
                end;
            DATABASE::"Contact Profile Answer":
                begin
                    ContProfileAnswer.SetView(TableView);
                    ContProfileAnswer.CopyFilter(
                      "Profile Questionnaire Code", ProfileQuestionnaireLine."Profile Questionnaire Code");
                    ContProfileAnswer.CopyFilter("Line No.", ProfileQuestionnaireLine."Line No.");
                    if ProfileQuestionnaireLine.Count = 1 then begin
                        ProfileQuestionnaireLine.FindFirst();
                        exit(SelectStr(1, ContProfileAnswer.GetFilters) + ', ' +
                          ProfileQuestionnaireLine.Question() + ': ' + ProfileQuestionnaireLine.Description);
                    end;
                    exit(ContProfileAnswer.GetFilters());
                end;
        end;

        OnAfterGetSegCriteriaFilters(TableNo, TableView, TableFilters);
#if not CLEAN22
        OnAfterSegCriteriaFilter(TableNo, TableView, TableFilters);
#endif
        exit(TableFilters);
    end;

#if not CLEAN22
    [Obsolete('Replaced by procedure GetSegCriteriaFilters()', '22.0')]
    procedure SegCriteriaFilter(TableNo: Integer; View: Text[250]): Text[250]
    begin
        exit(CopyStr(GetSegCriteriaFilters(TableNo, View), 1, 250));
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSegCriteriaFilters(TableNo: Integer; TableView: Text; var TableFilters: Text)
    begin
    end;

#if not CLEAN22
    [Obsolete('Replaced by event OnAfterGetSegCriteriaFilters()', '22.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSegCriteriaFilter(TableNo: Integer; View: Text[250]; var Filters: Text[250])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCriteriaAction(SegmentNo: Code[20]; var CalledFromReportNo: Integer; var AllowExistingContacts: Boolean; var ExpandContact: Boolean; var AllowCompanyWithPersons: Boolean; var IgnoreExclusion: Boolean; var EntireCompanies: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCriteriaActionOnBeforeSegCriteriaLineInsert(var SegCriteriaLine: Record "Segment Criteria Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCriteriaActionOnCalledFromReportNoElseCase(var SegCriteriaLine: Record "Segment Criteria Line"; CalledFromReportNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSegmentCriteriaFilter(SegmentNo: Code[20]; var TableNo: Integer; var TableFilter: Text; var TableView: Text; var Handled: Boolean)
    begin
    end;

#if not CLEAN22
    [Obsolete('Replaced by event OnBeforeInsertSegmentCriteriaFilter()', '22.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCriteriaFilter(SegmentNo: Code[20]; var TableNo: Integer; var "Filter": Text[250]; var View: Text[250]; var Handled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCriteriaFilterOnBeforeSegCriteriaLineInsert(var SegCriteriaLine: Record "Segment Criteria Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCriteriaFilterOnBeforeSegCriteriaLineModify(var SegCriteriaLine: Record "Segment Criteria Line")
    begin
    end;
}

