codeunit 130000 Assert
{

    trigger OnRun()
    begin
    end;

    var
        IsTrueFailedMsg: Label 'Assert.IsTrue failed. %1';
        IsFalseFailedMsg: Label 'Assert.IsFalse failed. %1';
        AreEqualFailedMsg: Label 'Assert.AreEqual failed. Expected:<%1> (%2). Actual:<%3> (%4). %5.', Locked = true;
        AreNotEqualFailedMsg: Label 'Assert.AreNotEqual failed. Expected any value except:<%1> (%2). Actual:<%3> (%4). %5.', Locked = true;
        AreNearlyEqualFailedMsg: Label 'Assert.AreNearlyEqual failed. Expected a difference no greater than <%1> between expected value <%2> and actual value <%3>. %4';
        AreNotNearlyEqualFailedMsg: Label 'Assert.AreNotNearlyEqual failed. Expected a difference greater than <%1> between expected value <%2> and actual value <%3>. %4';
        RecordsAreEqualExceptCertainFieldsErr: Label 'Assert.RecordsAreEqualExceptCertainFields failed. Expected the records to match. Difference found in <%1>. Left value <%2>, Right value <%3>. %4';
        FailFailedMsg: Label 'Assert.Fail failed. %1';
        TableIsEmptyErr: Label 'Assert.TableIsEmpty failed. Table <%1> with filter <%2> must not contain records.', Locked = true;
        TableIsNotEmptyErr: Label 'Assert.TableIsNotEmpty failed. Table <%1> with filter <%2> must contain records.', Locked = true;
        KnownFailureMsg: Label 'Known failure: see VSTF Bug #%1.';
        ExpectedErrorFailed: Label 'Assert.ExpectedError failed. Expected: %1. Actual: %2.';
        ExpectedErrorCodeFailed: Label 'Assert.ExpectedErrorCode failed. Expected: %1. Actual: %2. Actual error message: %3.';
        ExpectedMessageFailedErr: Label 'Assert.ExpectedMessage failed. Expected: %1. Actual: %2.';
        ExpectedConfirmFailedErr: Label 'Assert.ExpectedConfirm failed. Expected: %1. Actual: %2.';
        ExpectedStrMenuInstructionFailedErr: Label 'Assert.ExpectedStrMenu failed. Expected instruction: %1. Actual instruction: %2.';
        ExpectedStrMenuOptionsFailedErr: Label 'Assert.ExpectedStrMenu failed. Expected options: %1. Actual options: %2.';
        IsSubstringFailedErr: Label 'Assert.IsSubstring failed. Expected <%1> to be a substring of <%2>.';
        RecordCountErr: Label 'Assert.RecordCount failed. Expected number of %1 entries: %2. Actual: %3. Filters: %4.', Locked = true;
        UnsupportedTypeErr: Label 'Equality assertions only support Boolean, Option, Integer, BigInteger, Decimal, Code, Text, Date, DateFormula, Time, Duration, and DateTime values. Current value:%1.';
        RecordNotFoundErrorCode: Label 'DB:RecordNotFound';
        RecordAlreadyExistsErrorCode: Label 'DB:RecordExists';
        RecordNothingInsideFilterErrorCode: Label 'DB:NothingInsideFilter';
        AssertErrorMsg: Label 'Expected error %1 actual %2';
        PrimRecordNotFoundErrorCode: Label 'DB:PrimRecordNotFound';
        NoFilterErrorCode: Label 'DB:NoFilter';
        ErrorHasNotBeenThrownErr: Label 'The error has not been thrown.';
        TextEndsWithErr: Label 'Assert.TextEndsWith failed. The text <%1> must end with <%2>';
        TextEndSubstringIsBlankErr: Label 'Substring must not be blank.';

    procedure IsTrue(Condition: Boolean; Msg: Text)
    begin
        if not Condition then
            Error(IsTrueFailedMsg, Msg)
    end;

    procedure IsFalse(Condition: Boolean; Msg: Text)
    begin
        if Condition then
            Error(IsFalseFailedMsg, Msg)
    end;

    procedure AreEqual(Expected: Variant; Actual: Variant; Msg: Text)
    begin
        if not Equal(Expected, Actual) then
            Error(AreEqualFailedMsg, Expected, TypeNameOf(Expected), Actual, TypeNameOf(Actual), Msg)
    end;

    procedure AreNotEqual(Expected: Variant; Actual: Variant; Msg: Text)
    begin
        if Equal(Expected, Actual) then
            Error(AreNotEqualFailedMsg, Expected, TypeNameOf(Expected), Actual, TypeNameOf(Actual), Msg)
    end;

    procedure AreNearlyEqual(Expected: Decimal; Actual: Decimal; Delta: Decimal; Msg: Text)
    begin
        if Abs(Expected - Actual) > Abs(Delta) then
            Error(AreNearlyEqualFailedMsg, Delta, Expected, Actual, Msg)
    end;

    procedure AreNotNearlyEqual(Expected: Decimal; Actual: Decimal; Delta: Decimal; Msg: Text)
    begin
        if Abs(Expected - Actual) <= Abs(Delta) then
            Error(AreNotNearlyEqualFailedMsg, Delta, Expected, Actual, Msg)
    end;

    procedure Fail(Msg: Text)
    begin
        Error(FailFailedMsg, Msg)
    end;

    procedure RecordIsEmpty(RecVariant: Variant)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVariant);
        RecRefIsEmpty(RecRef);
    end;

    procedure RecordIsEmpty(RecVariant: Variant; CompanyName: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVariant);
        RecRef.ChangeCompany(CompanyName);
        RecRefIsEmpty(RecRef);
    end;

    procedure RecordIsNotEmpty(RecVariant: Variant; CompanyName: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVariant);
        RecRef.ChangeCompany(CompanyName);
        RecRefIsNotEmpty(RecRef);
    end;

    procedure RecordIsNotEmpty(RecVariant: Variant)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVariant);
        RecRefIsNotEmpty(RecRef);
    end;

    procedure TableIsEmpty(TableNo: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        RecRefIsEmpty(RecRef);
        RecRef.Close();
    end;

    procedure TableIsNotEmpty(TableNo: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        RecRefIsNotEmpty(RecRef);
        RecRef.Close();
    end;

    local procedure RecRefIsEmpty(var RecRef: RecordRef)
    begin
        if not RecRef.IsEmpty() then
            Error(TableIsEmptyErr, RecRef.Caption, RecRef.GetFilters);
    end;

    local procedure RecRefIsNotEmpty(var RecRef: RecordRef)
    begin
        if RecRef.IsEmpty() then
            Error(TableIsNotEmptyErr, RecRef.Caption, RecRef.GetFilters);
    end;

    procedure RecordCount(RecVariant: Variant; ExpectedCount: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVariant);
        if ExpectedCount <> RecRef.Count then
            Error(RecordCountErr, RecRef.Caption, ExpectedCount, RecRef.Count, RecRef.GetFilters);
        RecRef.Close();
    end;

    procedure KnownFailure(Expected: Text; WorkItemNo: Integer)
    begin
        ExpectedError(Expected);
        Error(KnownFailureMsg, WorkItemNo)
    end;

    procedure ExpectedError(Expected: Text)
    begin
        if (GetLastErrorText = '') and (Expected = '') then begin
            if GetLastErrorCallstack = '' then
                Error(ErrorHasNotBeenThrownErr);
        end else
            if StrPos(GetLastErrorText, Expected) = 0 then
                Error(ExpectedErrorFailed, Expected, GetLastErrorText);
    end;

    procedure ExpectedErrorCode(Expected: Text)
    begin
        if StrPos(GetLastErrorCode, Expected) = 0 then
            Error(ExpectedErrorCodeFailed, Expected, GetLastErrorCode, GetLastErrorText);
    end;

    procedure ExpectedMessage(Expected: Text; Actual: Text)
    begin
        ExpectedDialog(Expected, Actual, ExpectedMessageFailedErr);
    end;

    procedure ExpectedConfirm(Expected: Text; Actual: Text)
    begin
        ExpectedDialog(Expected, Actual, ExpectedConfirmFailedErr);
    end;

    procedure ExpectedStrMenu(ExpectedInstruction: Text; ExpectedOptions: Text; ActualInstruction: Text; ActualOptions: Text)
    begin
        ExpectedDialog(ExpectedInstruction, ActualInstruction, ExpectedStrMenuInstructionFailedErr);
        ExpectedDialog(ExpectedOptions, ActualOptions, ExpectedStrMenuOptionsFailedErr);
    end;

    local procedure ExpectedDialog(Expected: Text; Actual: Text; ErrorMessage: Text)
    begin
        if Expected = Actual then
            exit;
        if StrPos(Actual, Expected) = 0 then
            Error(ErrorMessage, Expected, Actual);
    end;

    procedure IsDataTypeSupported(Value: Variant): Boolean
    begin
        exit(Value.IsBoolean or
          Value.IsOption or
          Value.IsInteger or
          Value.IsDecimal or
          Value.IsText or
          Value.IsCode or
          Value.IsDate or
          Value.IsDateTime or
          Value.IsDateFormula or
          Value.IsGuid or
          Value.IsDuration or
          Value.IsRecordId or
          Value.IsBigInteger or
          Value.IsChar or
          Value.IsTime);
    end;

    procedure TextEndsWith(OriginalText: Text; Substring: Text)
    var
        ErrorMessage: Text;
    begin
        if Substring = '' then
            Error(TextEndSubstringIsBlankErr);
        ErrorMessage := StrSubstNo(TextEndsWithErr, OriginalText, Substring);
        AreEqual(StrLen(OriginalText) - StrLen(Substring) + 1, StrPos(OriginalText, Substring), ErrorMessage);
    end;

    procedure IsSubstring(OriginalText: Text; Substring: Text)
    begin
        if Substring = '' then
            Error(TextEndSubstringIsBlankErr);

        if StrPos(OriginalText, Substring) <= 0 then
            Error(IsSubstringFailedErr, Substring, OriginalText);
    end;

    local procedure TypeOf(Value: Variant): Integer
    var
        "Field": Record "Field";
    begin
        case true of
            Value.IsBoolean:
                exit(Field.Type::Boolean);
            Value.IsOption or Value.IsInteger or Value.IsByte:
                exit(Field.Type::Integer);
            Value.IsBigInteger:
                exit(Field.Type::BigInteger);
            Value.IsDecimal:
                exit(Field.Type::Decimal);
            Value.IsText or Value.IsCode or Value.IsChar or Value.IsTextConstant:
                exit(Field.Type::Text);
            Value.IsDate:
                exit(Field.Type::Date);
            Value.IsTime:
                exit(Field.Type::Time);
            Value.IsDuration:
                exit(Field.Type::Duration);
            Value.IsDateTime:
                exit(Field.Type::DateTime);
            Value.IsDateFormula:
                exit(Field.Type::DateFormula);
            Value.IsGuid:
                exit(Field.Type::GUID);
            Value.IsRecordId:
                exit(Field.Type::RecordID);
            else
                Error(UnsupportedTypeErr, UnsupportedTypeName(Value))
        end
    end;

    local procedure TypeNameOf(Value: Variant): Text
    var
        "Field": Record "Field";
    begin
        Field.Type := TypeOf(Value);
        exit(Format(Field.Type));
    end;

    local procedure UnsupportedTypeName(Value: Variant): Text
    begin
        case true of
            Value.IsRecord:
                exit('Record');
            Value.IsRecordRef:
                exit('RecordRef');
            Value.IsFieldRef:
                exit('FieldRef');
            Value.IsCodeunit:
                exit('Codeunit');
            Value.IsAutomation:
                exit('Automation');
            Value.IsFile:
                exit('File');
        end;
        exit('Unsupported Type');
    end;

    procedure Compare(Left: Variant; Right: Variant): Boolean
    begin
        exit(Equal(Left, Right))
    end;

    procedure Equal(Left: Variant; Right: Variant): Boolean
    begin
        if IsNumber(Left) and IsNumber(Right) then
            exit(EqualNumbers(Left, Right));

        if Left.IsDotNet or Right.IsDotNet then
            exit((Format(Left, 0, 2) = Format(Right, 0, 2)));

        exit((TypeOf(Left) = TypeOf(Right)) and (Format(Left, 0, 2) = Format(Right, 0, 2)))
    end;

    local procedure EqualNumbers(Left: Decimal; Right: Decimal): Boolean
    begin
        exit(Left = Right)
    end;

    local procedure IsNumber(Value: Variant): Boolean
    begin
        exit(Value.IsDecimal or Value.IsInteger or Value.IsChar)
    end;

    procedure VerifyFailure(expectedErrorCode: Text; failureText: Text)
    var
        errorCode: Text;
    begin
        errorCode := GetLastErrorCode;

        IsTrue(errorCode = expectedErrorCode, failureText);
        ClearLastError();
    end;

    procedure AssertRecordNotFound()
    begin
        VerifyFailure(RecordNotFoundErrorCode, StrSubstNo(AssertErrorMsg, RecordNotFoundErrorCode, GetLastErrorCode));
    end;

    procedure AssertRecordAlreadyExists()
    begin
        VerifyFailure(RecordAlreadyExistsErrorCode, StrSubstNo(AssertErrorMsg, RecordAlreadyExistsErrorCode, GetLastErrorCode));
    end;

    procedure AssertNothingInsideFilter()
    begin
        VerifyFailure(RecordNothingInsideFilterErrorCode, StrSubstNo(AssertErrorMsg, RecordNothingInsideFilterErrorCode, GetLastErrorCode));
    end;

    procedure AssertNoFilter()
    begin
        VerifyFailure(NoFilterErrorCode, StrSubstNo(AssertErrorMsg, NoFilterErrorCode, GetLastErrorCode));
    end;

    procedure AssertPrimRecordNotFound()
    begin
        VerifyFailure(PrimRecordNotFoundErrorCode, StrSubstNo(AssertErrorMsg, PrimRecordNotFoundErrorCode, GetLastErrorCode));
    end;

    procedure RecordsAreEqualExceptCertainFields(var RecordRefLeft: RecordRef; var RecordRefRight: RecordRef; var TempFieldToIgnore: Record "Field" temporary; Msg: Text): Boolean
    var
        LeftFieldRef: FieldRef;
        RightFieldRef: FieldRef;
        i: Integer;
    begin
        // Records <Left> and <Right> are considered equal when each (Normal) <Left> field
        // has the same value as the <Right> field with the same index.
        // Note that for performance reasons this function does not take into account,
        // whether the two records have the same number of fields.
        // It assumes that the records belong to the same table.

        for i := 1 to RecordRefLeft.FieldCount do begin
            LeftFieldRef := RecordRefLeft.FieldIndex(i);
            if LeftFieldRef.Class = FieldClass::Normal then begin
                RightFieldRef := RecordRefRight.FieldIndex(i);

                if not TempFieldToIgnore.Get(RecordRefLeft.Number, LeftFieldRef.Number) then
                    if LeftFieldRef.Value <> RightFieldRef.Value then
                        Error(RecordsAreEqualExceptCertainFieldsErr, LeftFieldRef.Name, LeftFieldRef.Value, RightFieldRef.Value, Msg);
            end;
        end;
        exit(true);
    end;
}

