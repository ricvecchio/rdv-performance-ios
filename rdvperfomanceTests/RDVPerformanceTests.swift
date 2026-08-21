// RDVPerformanceTests.swift
// Testes unitários para lógica pura do app RDV Performance.
//
// ⚠️ ATENÇÃO: Este arquivo precisa ser adicionado a um test target no Xcode.
// Para criar o target: File → New Target → Unit Testing Bundle.
// Em seguida, adicione este arquivo ao novo target.

import XCTest
@testable import rdvperfomance

// MARK: - BrazilianPhoneFormatter Tests

final class BrazilianPhoneFormatterTests: XCTestCase {

    // MARK: normalize

    func testNormalize_digitsOnly() {
        XCTAssertEqual(BrazilianPhoneFormatter.normalize("11988888888"), "11988888888")
    }

    func testNormalize_formattedInput() {
        XCTAssertEqual(BrazilianPhoneFormatter.normalize("(11) 98888-8888"), "11988888888")
    }

    func testNormalize_mixedInput() {
        XCTAssertEqual(BrazilianPhoneFormatter.normalize("abc11988888888"), "11988888888")
    }

    func testNormalize_truncatesAt11() {
        XCTAssertEqual(BrazilianPhoneFormatter.normalize("119888888881234"), "11988888888")
    }

    func testNormalize_emptyInput() {
        XCTAssertEqual(BrazilianPhoneFormatter.normalize(""), "")
    }

    // MARK: format

    func testFormat_cellphone11Digits() {
        XCTAssertEqual(BrazilianPhoneFormatter.format("11988888888"), "(11) 98888-8888")
    }

    func testFormat_landline10Digits() {
        XCTAssertEqual(BrazilianPhoneFormatter.format("1150505050"), "(11) 5050-5050")
    }

    func testFormat_alreadyFormatted() {
        // Deve normalizar e reformatar corretamente
        XCTAssertEqual(BrazilianPhoneFormatter.format("(11) 98888-8888"), "(11) 98888-8888")
    }

    func testFormat_mixedChars() {
        XCTAssertEqual(BrazilianPhoneFormatter.format("abc11988888888"), "(11) 98888-8888")
    }

    func testFormat_empty() {
        XCTAssertEqual(BrazilianPhoneFormatter.format(""), "")
    }

    func testFormat_partial2Digits() {
        XCTAssertEqual(BrazilianPhoneFormatter.format("11"), "(11")
    }

    func testFormat_partial5Digits() {
        XCTAssertEqual(BrazilianPhoneFormatter.format("11988"), "(11) 988")
    }

    // MARK: isValid

    func testIsValid_empty() {
        XCTAssertTrue(BrazilianPhoneFormatter.isValid(""))
    }

    func testIsValid_10digits() {
        XCTAssertTrue(BrazilianPhoneFormatter.isValid("1150505050"))
    }

    func testIsValid_11digits() {
        XCTAssertTrue(BrazilianPhoneFormatter.isValid("11988888888"))
    }

    func testIsValid_9digits_invalid() {
        XCTAssertFalse(BrazilianPhoneFormatter.isValid("119888888"))
    }

    func testIsValid_12digits_invalid() {
        XCTAssertFalse(BrazilianPhoneFormatter.isValid("119888888881"))
    }

    func testIsValid_formattedCellphone() {
        XCTAssertTrue(BrazilianPhoneFormatter.isValid("(11) 98888-8888"))
    }
}

// MARK: - WeightParser Tests

final class WeightParserTests: XCTestCase {

    // MARK: parse

    func testParse_commaDecimal() {
        XCTAssertEqual(WeightParser.parse("183,7"), 183.7)
    }

    func testParse_dotDecimal() {
        XCTAssertEqual(WeightParser.parse("183.70"), 183.7)
    }

    func testParse_integer() {
        XCTAssertEqual(WeightParser.parse("405"), 405.0)
    }

    func testParse_commaZeros() {
        XCTAssertEqual(WeightParser.parse("405,00"), 405.0)
    }

    func testParse_zero() {
        XCTAssertEqual(WeightParser.parse("0"), 0.0)
    }

    func testParse_twoCommas_invalid() {
        XCTAssertNil(WeightParser.parse("183,,7"))
    }

    func testParse_twoDots_invalid() {
        XCTAssertNil(WeightParser.parse("183..7"))
    }

    func testParse_letters_invalid() {
        XCTAssertNil(WeightParser.parse("abc"))
    }

    func testParse_empty_invalid() {
        XCTAssertNil(WeightParser.parse(""))
    }

    func testParse_moreThan2Decimals_invalid() {
        XCTAssertNil(WeightParser.parse("183.701"))
    }

    func testParse_commaMoreThan2Decimals_invalid() {
        XCTAssertNil(WeightParser.parse("183,701"))
    }

    // MARK: display

    func testDisplay_kgFormat() {
        XCTAssertEqual(WeightParser.display(183.7, unit: "kg"), "183,70 kg")
    }

    func testDisplay_lbFormat() {
        XCTAssertEqual(WeightParser.display(405.0, unit: "lb"), "405,00 lb")
    }

    func testDisplay_integer_twoDecimals() {
        XCTAssertEqual(WeightParser.display(100.0, unit: "kg"), "100,00 kg")
    }

    // MARK: brazilianFormat

    func testBrazilianFormat_noTrailingZeros() {
        // Sempre 2 casas decimais
        XCTAssertEqual(WeightParser.brazilianFormat(183.7), "183,70")
    }

    func testBrazilianFormat_integer() {
        XCTAssertEqual(WeightParser.brazilianFormat(405.0), "405,00")
    }
}
