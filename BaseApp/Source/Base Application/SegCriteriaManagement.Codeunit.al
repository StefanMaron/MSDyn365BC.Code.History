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
        InsertCriteriaFilter(SegmentNo, DATABASE::Contact, Cont.GetFilters, Cont.GetView(false));
    end;

    procedure DeleteContact(SegmentNo: Code[20]; ContactNo: Code[20])
    var
        Cont: Record Contact;
    begin
        Cont.SetRange("No.", ContactNo);

        InsertCriteriaAction(SegmentNo, REPORT::"Remove Contacts - Reduce", false, false, false, false, false);
        InsertCriteriaFilter(SegmentNo, DATABASE::Contact, Cont.GetFilters, Cont.GetView(false));
    end;

    procedure InsertReuseLogged(SegmentNo: Code[20]; LoggedSegmentEntryNo: Integer)
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        InteractLogEntry.SetCurrentKey("Logged Segment Entry No.");
        InteractLogEntry.SetRange("Logged Segment Entry No.", LoggedSegmentEntryNo);

        InsertCriteriaAction(SegmentNo, REPORT::"Add Contacts", true, false, false, false, false);
        InsertCriteriaFilter(
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
        if SegCriteriaLine.FindLast then
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

    procedure InsertCriteriaFilter(SegmentNo: Code[20]; TableNo: Integer; "Filter": Text[250]; View: Text[250])
    var
        SegCriteriaLine: Record "Segment Criteria Line";
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertCriteriaFilter(SegmentNo, TableNo, Filter, View, IsHandled);
        if IsHandled then
            exit;

        if Filter = '' then
            exit;

        SegCriteriaLine.SetRange("Segment No.", SegmentNo);
        if SegCriteriaLine.FindLast then
            NextLineNo := SegCriteriaLine."Line No." + 1
        else
            NextLineNo := 1;

        SegCriteriaLine.Init();
        SegCriteriaLine."Segment No." := SegmentNo;
        SegCriteriaLine."Line No." := NextLineNo;
        SegCriteriaLine.Type := SegCriteriaLine.Type::Filter;
        SegCriteriaLine."Table No." := TableNo;
        SegCriteriaLine.View := View;
        OnBeforeInsertCriteriaFilterOnBeforeSegCriteriaLineInsert(SegCriteriaLine);
        SegCriteriaLine.Insert();

        SegCriteriaLine.Reset();
        SegCriteriaLine.SetCurrentKey("Segment No.", Type);
        SegCriteriaLine.SetRange("Segment No.", SegmentNo);
        SegCriteriaLine.SetRange(Type, SegCriteriaLine.Type::Action);
        SegCriteriaLine.FindLast;
        SegCriteriaLine."No. of Filters" := SegCriteriaLine."No. of Filters" + 1;
        OnBeforeInsertCriteriaFilterOnBeforeSegCriteriaLineModify(SegCriteriaLine);
        SegCriteriaLine.Modify();
    end;

    procedure SegCriteriaFilter(TableNo: Integer; View: Text[250]): Text[250]
    var
        Cont: Record Contact;
        ContProfileAnswer: Record "Contact Profile Answer";
        ContMailingGrp: Record "Contact Mailing Group";
        InteractLogEntry: Record "Interaction Log Entry";
        ContJobResp: Record "Contact Job Responsibility";
        ContIndustGrp: Record "Contact Industry Group";
        ContBusRel: Record "Contact Business Relation";
        ValueEntry: Record "Value Entry";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        Filters: Text[250];
    begin
        case TableNo of
            DATABASE::Contact:
                begin
                    Cont.SetView(View);
                    exit(Cont.GetFilters);
                end;
            DATABASE::"Contact Profile Answer":
                begin
                    ContProfileAnswer.SetView(View);
                    ContProfileAnswer.CopyFilter(
                      "Profile Questionnaire Code", ProfileQuestionnaireLine."Profile Questionnaire Code");
                    ContProfileAnswer.CopyFilter("Line No.", ProfileQuestionnaireLine."Line No.");
                    if ProfileQuestionnaireLine.Count = 1 then begin
                        ProfileQuestionnaireLine.FindFirst;
                        exit(SelectStr(1, ContProfileAnswer.GetFilters) + ', ' +
                          ProfileQuestionnaireLine.Question + ': ' + ProfileQuestionnaireLine.Description);
                    end;
                    exit(ContProfileAnswer.GetFilters);
                end;
            DATABASE::"Contact Mailing Group":
                begin
                    ContMailingGrp.SetView(View);
                    exit(ContMailingGrp.GetFilters);
                end;
            DATABASE::"Interaction Log Entry":
                begin
                    InteractLogEntry.SetView(View);
                    exit(InteractLogEntry.GetFilters);
                end;
            DATABASE::"Contact Job Responsibility":
                begin
                    ContJobResp.SetView(View);
                    exit(ContJobResp.GetFilters);
                end;
            DATABASE::"Contact Industry Group":
                begin
                    ContIndustGrp.SetView(View);
                    exit(ContIndustGrp.GetFilters);
                end;
            DATABASE::"Contact Business Relation":
                begin
                    ContBusRel.SetView(View);
                    exit(ContBusRel.GetFilters);
                end;
            DATABASE::"Value Entry":
                begin
                    ValueEntry.SetView(View);
                    exit(ValueEntry.GetFilters);
                end;
        end;

        OnAfterSegCriteriaFilter(TableNo, View, Filters);
        exit(Filters);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSegCriteriaFilter(TableNo: Integer; View: Text[250]; var Filters: Text[250])
    begin
    end;

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
    local procedure OnBeforeInsertCriteriaFilter(SegmentNo: Code[20]; var TableNo: Integer; var "Filter": Text[250]; var View: Text[250]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCriteriaFilterOnBeforeSegCriteriaLineInsert(var SegCriteriaLine: Record "Segment Criteria Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCriteriaFilterOnBeforeSegCriteriaLineModify(var SegCriteriaLine: Record "Segment Criteria Line")
    begin
    end;
}

