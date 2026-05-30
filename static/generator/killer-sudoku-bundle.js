(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.killerSudoku = f()}})(function(){var define,module,exports;return (function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
// const {
//   generateKillerSudoku,
//   getSeparationsFromAreas,
// } = require("killer-sudoku-generator");

// const sudoku = generateKillerSudoku();

// const { puzzle, solution, areas, difficulty } = sudoku;

// const { verticalSeparations, horizontalSeparations } =
//   getSeparationsFromAreas(areas);

// console.log("======================sudoku================================");
// console.log(sudoku);
// for (let i = 0; i < sudoku.areas.length; i++) {
//   console.log(sudoku.areas[i].cells);
// }
// console.log(
//   "==========================verticalSeparations=======================================================",
// );

// console.log(verticalSeparations);
// console.log(
//   "==========================horizontalSeparations=======================================================",
// );

// console.log(horizontalSeparations);

module.exports = require("killer-sudoku-generator");

},{"killer-sudoku-generator":2}],2:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.overrideNumberOfCellsToRemove = exports.getSeparationsFromAreas = exports.generateKillerSudoku = void 0;
var utils_1 = require("./utils");
Object.defineProperty(exports, "generateKillerSudoku", { enumerable: true, get: function () { return utils_1.generateKillerSudoku; } });
var areaSeparations_1 = require("./utils/analyze/areaSeparations");
Object.defineProperty(exports, "getSeparationsFromAreas", { enumerable: true, get: function () { return areaSeparations_1.getSeparationsFromAreas; } });
var preparePuzzle_1 = require("./utils/prepare/preparePuzzle");
Object.defineProperty(exports, "overrideNumberOfCellsToRemove", { enumerable: true, get: function () { return preparePuzzle_1.overrideNumberOfCellsToRemove; } });

},{"./utils":6,"./utils/analyze/areaSeparations":3,"./utils/prepare/preparePuzzle":8}],3:[function(require,module,exports){
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSeparationsFromAreas = void 0;
const Coords_1 = __importDefault(require("../model/Coords"));
/**
 * Takes an areas list and returns a matrix representing the separations between the areas.
 *
 * @param areas Areas list to get separations from.
 */
function getSeparationsFromAreas(areas) {
    const areasGrid = areasToGridOfID(areas);
    const verticalSeparations = [];
    const horizontalSeparations = [];
    for (let j = 0; j < 9; j++) {
        for (let i = 0; i < 8; i++) {
            if (areasGrid[j + i * 9] !== areasGrid[j + (i + 1) * 9]) {
                verticalSeparations.push((0, Coords_1.default)(j, i));
            }
        }
    }
    for (let i = 0; i < 9; i++) {
        for (let j = 0; j < 8; j++) {
            if (areasGrid[j + i * 9] !== areasGrid[j + 1 + i * 9]) {
                horizontalSeparations.push((0, Coords_1.default)(i, j));
            }
        }
    }
    return { verticalSeparations, horizontalSeparations };
}
exports.getSeparationsFromAreas = getSeparationsFromAreas;
function areasToGridOfID(areas) {
    var areasGrid = "-".repeat(81).split("");
    areas.forEach((area, i) => {
        area.cells.forEach(([x, y]) => {
            areasGrid[x + y * 9] = `${i}`;
        });
    });
    return areasGrid;
}

},{"../model/Coords":7}],4:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function isComplete(areas) {
    return areas.map((area) => area.cells.length).reduce((a, b) => a + b, 0) === 81;
}
function findAvailableCell(areas) {
    const usedCells = areas.flatMap((area) => area.cells);
    const availableCells = [];
    for (let i = 0; i < 9; i++) {
        for (let j = 0; j < 9; j++) {
            if (!usedCells.some((cell) => cell[0] === i && cell[1] === j)) {
                availableCells.push([i, j]);
            }
        }
    }
    return availableCells[Math.floor(Math.random() * availableCells.length)];
}
function addCellToArea(area, cell, sudoku) {
    area.cells.push(cell);
    area.sum += parseInt(sudoku.solution[cell[0] * 9 + cell[1]]);
}
function getAvailableAdjacentCells(currentArea, currentCell, areas, solution) {
    const adjacentCells = [
        [currentCell[0] - 1, currentCell[1]],
        [currentCell[0] + 1, currentCell[1]],
        [currentCell[0], currentCell[1] - 1],
        [currentCell[0], currentCell[1] + 1],
    ].filter((cell) => cell[0] >= 0 && cell[0] <= 8 && cell[1] >= 0 && cell[1] <= 8);
    const usedCells = areas.flatMap((area) => area.cells).concat(currentArea.cells);
    const currentAreaNumbers = currentArea.cells.map((cell) => solution[cell[0] * 9 + cell[1]]);
    return adjacentCells
        .filter((cell) => !usedCells.some((usedCell) => usedCell[0] === cell[0] && usedCell[1] === cell[1]))
        .filter(([i, j]) => !currentAreaNumbers.includes(solution[i * 9 + j]));
}
function generateAreas(sudoku) {
    const areas = [];
    while (!isComplete(areas)) {
        const area = { cells: [], sum: 0 };
        const startingCell = findAvailableCell(areas);
        addCellToArea(area, startingCell, sudoku);
        const maxAreaLength = Math.floor(Math.random() * 6) + 2; // 2-7
        var lastCell = startingCell;
        while (area.cells.length < maxAreaLength) {
            const availableAdjacentCells = getAvailableAdjacentCells(area, lastCell, areas, sudoku.solution);
            if (availableAdjacentCells.length === 0) {
                break;
            }
            const nextCell = availableAdjacentCells[Math.floor(Math.random() * availableAdjacentCells.length)];
            addCellToArea(area, nextCell, sudoku);
            lastCell = nextCell;
        }
        areas.push(area);
    }
    sudoku.areas = areas;
}
exports.default = generateAreas;

},{}],5:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const sudoku_gen_1 = require("sudoku-gen");
function generateFullSudokuGridWithoutAreas(difficulty) {
    const { solution } = (0, sudoku_gen_1.getSudoku)(difficulty);
    return { puzzle: solution, solution, difficulty, areas: [] };
}
exports.default = generateFullSudokuGridWithoutAreas;

},{"sudoku-gen":13}],6:[function(require,module,exports){
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateKillerSudoku = void 0;
const areas_1 = __importDefault(require("./generation/areas"));
const generate_1 = __importDefault(require("./generation/generate"));
const preparePuzzle_1 = __importDefault(require("./prepare/preparePuzzle"));
/**
 * Generates a full killer sudoku grid.
 *
 * @param difficulty Difficulty of the sudoku to generate. Defaults to "expert".
 */
function generateKillerSudoku(difficulty) {
    const sudoku = (0, generate_1.default)(difficulty || "expert");
    (0, areas_1.default)(sudoku);
    sudoku.puzzle = (0, preparePuzzle_1.default)(sudoku.solution, sudoku.difficulty, sudoku.areas);
    return sudoku;
}
exports.generateKillerSudoku = generateKillerSudoku;

},{"./generation/areas":4,"./generation/generate":5,"./prepare/preparePuzzle":8}],7:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const coords = Array.from({ length: 81 }, (_, i) => [Math.floor(i / 9), i % 9]);
function Coords(x, y) {
    return coords[x * 9 + y];
}
exports.default = Coords;

},{}],8:[function(require,module,exports){
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.overrideNumberOfCellsToRemove = void 0;
const backtrackSolve_1 = __importDefault(require("../solver/backtrackSolve"));
var numberOfCellsToRemove = {
    easy: 30,
    medium: 40,
    hard: 50,
    expert: 60,
};
/**
 * Override the number of cells to remove from the puzzle for a given difficulty.
 *
 * @param difficulty Difficulty to override the number of cells to remove from
 * @param number The new number of cells to remove for this difficulty
 */
function overrideNumberOfCellsToRemove(difficulty, number) {
    numberOfCellsToRemove[difficulty] = number;
}
exports.overrideNumberOfCellsToRemove = overrideNumberOfCellsToRemove;
function preparePuzzle(solution, difficulty, areas) {
    var puzzle = solution.slice(0).split("");
    let emptyCells = 0;
    while (emptyCells < numberOfCellsToRemove[difficulty]) {
        const notEmptyCellIndexes = puzzle
            .map((cell, index) => (cell === "-" ? -1 : index))
            .filter((index) => index !== -1);
        const index = notEmptyCellIndexes[Math.floor(Math.random() * notEmptyCellIndexes.length)];
        if (puzzle[index] !== "-") {
            const temp = puzzle[index];
            puzzle[index] = "-";
            if (!(0, backtrackSolve_1.default)(puzzle, areas).solvable) {
                puzzle[index] = temp;
            }
            else {
                emptyCells++;
            }
        }
    }
    return puzzle.join("");
}
exports.default = preparePuzzle;

},{"../solver/backtrackSolve":9}],9:[function(require,module,exports){
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const Coords_1 = __importDefault(require("../model/Coords"));
function backtrackSolve(puzzle, areas) {
    const puzzleCopy = puzzle.slice(0);
    const solvable = backtrackSolveAux(puzzleCopy, areas);
    return { puzzle: puzzleCopy.join(""), solvable };
}
exports.default = backtrackSolve;
function backtrackSolveAux(puzzleCopy, areas) {
    const emptyCells = getEmptyCells(puzzleCopy);
    if (emptyCells.length === 0) {
        return true;
    }
    const cell = emptyCells[0];
    const [i, j] = cell;
    const row = getRow(puzzleCopy, i);
    const col = getCol(puzzleCopy, j);
    const box = getBox(puzzleCopy, i, j);
    const { area, currentSum, sum } = getArea(puzzleCopy, areas, i, j);
    for (let n = 1; n <= 9; n++) {
        if (!row.includes(`${n}`) &&
            !col.includes(`${n}`) &&
            !box.includes(`${n}`) &&
            !area.includes(`${n}`) &&
            currentSum + n <= sum) {
            puzzleCopy[i * 9 + j] = `${n}`;
            if (backtrackSolveAux(puzzleCopy, areas)) {
                return true;
            }
            puzzleCopy[i * 9 + j] = "-";
        }
    }
    return false;
}
function getEmptyCells(puzzle) {
    return puzzle
        .map((char, index) => {
        if (char === "-") {
            const i = Math.floor(index / 9);
            const j = index % 9;
            return (0, Coords_1.default)(i, j);
        }
        return undefined;
    })
        .filter((coord) => coord !== undefined);
}
function getRow(puzzle, i) {
    return puzzle.join("").slice(i * 9, i * 9 + 9);
}
function getCol(puzzle, j) {
    return puzzle
        .filter((_, index) => index % 9 === j)
        .join("");
}
function getBox(puzzle, i, j) {
    const boxI = Math.floor(i / 3);
    const boxJ = Math.floor(j / 3);
    return puzzle
        .filter((_, index) => {
        const i = Math.floor(index / 9);
        const j = index % 9;
        return Math.floor(i / 3) === boxI && Math.floor(j / 3) === boxJ;
    })
        .join("");
}
function getArea(puzzle, areas, i, j) {
    const area = areas.find((area) => area.cells.some((cell) => cell[0] === i && cell[1] === j));
    const currentSum = area.cells.reduce((sum, cell) => sum + (parseInt(puzzle[cell[0] * 9 + cell[1]]) || 0), 0);
    const areaString = area.cells.map((cell) => puzzle[cell[0] * 9 + cell[1]]).join("");
    return { area: areaString, currentSum, sum: area.sum };
}

},{"../model/Coords":7}],10:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BASE_LAYOUT = void 0;
exports.BASE_LAYOUT = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8],
    [9, 10, 11, 12, 13, 14, 15, 16, 17],
    [18, 19, 20, 21, 22, 23, 24, 25, 26],
    [27, 28, 29, 30, 31, 32, 33, 34, 35],
    [36, 37, 38, 39, 40, 41, 42, 43, 44],
    [45, 46, 47, 48, 49, 50, 51, 52, 53],
    [54, 55, 56, 57, 58, 59, 60, 61, 62],
    [63, 64, 65, 66, 67, 68, 69, 70, 71],
    [72, 73, 74, 75, 76, 77, 78, 79, 80],
];

},{}],11:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DIFFICULTY_LEVELS = void 0;
const DIFFICULTY_RECORD = {
    easy: undefined,
    medium: undefined,
    hard: undefined,
    expert: undefined,
};
exports.DIFFICULTY_LEVELS = Object.keys(DIFFICULTY_RECORD);

},{}],12:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SEEDS = void 0;
exports.SEEDS = [
    {
        puzzle: 'g--d--caf---g----ii-f--hg-bb-iaedhgc--afcg--d-g-b-----f-d--abc---b------c--h-bfia',
        solution: 'gbhdiecafacegbfdhiidfcahgebbfiaedhgcehafcgibddgcbhiafefidegabchhabifcedgceghdbfia',
        difficulty: 'easy',
    },
    {
        puzzle: 'bf-hiac-g-gi------a-hf-g---g-a-fi--ddef---i-b--b-a-g-ff---gbh--hac---------e-cfd-',
        solution: 'bfdhiacegegicbdafhachfegdbighabfiecddefgchiabcibdaeghffdeagbhichacidfbgeibgehcfda',
        difficulty: 'easy',
    },
    {
        puzzle: 'hgad-e--b-cbf-ge---df-aih-----i-------d-ecai-g---fa----igadf----fe-i-----h-eg-fd-',
        solution: 'hgadceifbicbfhgeadedfbaihcgcahibdgeffbdgecaihgeihfadbcbigadfchedfecihbgaahcegbfdi',
        difficulty: 'easy',
    },
    {
        puzzle: '-fbe-c----e-----a---g-ihb--gb-fhdc-eid-g-eahbch-----f-----ef-ga-g----e-i--hi-----',
        solution: 'afbegcidhheidfbgacdcgaihbefgbafhdcieidfgceahbchebaidfgbidcefhgafgchdaebieahibgfcd',
        difficulty: 'easy',
    },
    {
        puzzle: 'c--d-fgeb---g--i-hg-ih--da-a-g-b-cde-edc--a--b--------i-e-cd-ha-fb-h-e-ch--e-----',
        solution: 'cahdifgebedfgabichgbihecdafahgfbicdefedcghabibicadehfgigebcdfhadfbihaegchcaefgbid',
        difficulty: 'easy',
    },
    {
        puzzle: 'bi---ec--eg--h-fbdf--------i-hba-dfe----ehbig--bf-d-h--f-e-a-c-----g-e--cde--f--a',
        solution: 'bidgfecahegcahifbdfhadcbgeiichbagdfedafcehbiggebfidahchfgedaicbabihgcedfcdeibfhga',
        difficulty: 'easy',
    },
    {
        puzzle: '-----ef-ha--bf--ecfe-gc---a----gbch--a--df-b--bi----f-h-af-gidbdf----g--i--c--ha-',
        solution: 'bicdaefghahgbfidecfedgchbiaedfagbchicahidfebggbiehcafdhcafegidbdfbhiagceigecbdhaf',
        difficulty: 'easy',
    },
    {
        puzzle: '--fg--hec-ebc-------h-dfgabb--h-a-fg-g-df-i--f-a---b--hf----ad---if----hc-ea---bi',
        solution: 'dafgbihecgebcahdifichedfgabbidhcaefgegcdfbihafhaigebcdhfgbicadeabifedcghcdeahgfbi',
        difficulty: 'easy',
    },
    {
        puzzle: '-----b-f-e-aih----bi----a----e---i---g-bf--a-----cihg-ic-fdhg-a--h---f-cgef-iad-b',
        solution: 'dhcgabefiefaihcbdgbigdefachcaehgdibfhgibfecadfbdacihgeicbfdhgeaadhebgficgefciadhb',
        difficulty: 'easy',
    },
    {
        puzzle: 'e--f-b-------eid-f--h----b-ge-c-fadhab-ihgfe-hc--d----d-g---cf---eg--h-bf---i----',
        solution: 'edcfgbihabgaheidcfifhdcaebggeicbfadhabdihgfechcfadebgidigbahcfecaegfdhibfhbeicgad',
        difficulty: 'easy',
    },
    {
        puzzle: 'g-hedcf---i-f--a--e--a-----c--i-deh-i-------g--g--e---a----f--c-cf-e-gi-b-------e',
        solution: 'gahedcfbidicfbgaehefbaihcgdcbaigdehfihebfadcgfdghceiabaeighfbdchcfdebgiabgdcaihfe',
        difficulty: 'medium',
    },
    {
        puzzle: '-di--ac---b-cid-h---h--b-d-----f----h-d----fca---c-i--d----i-e-bh---cd-g-g---fac-',
        solution: 'fdighacbeebgcidfhacahfebgdigecifhbadhidabgefcafbdceighdcabgihefbhfeacdigigehdfacb',
        difficulty: 'medium',
    },
    {
        puzzle: '--ac-i------ah-d---e----i---a-e-bc----g--f--ad---gae--ig-fa------hd-e-g-c-d-b----',
        solution: 'hdaceigfbbifahgdcegecbfdiahfaiedbchgehgicfbdadcbhgaeifigefachbdabhdiefgccfdgbhaei',
        difficulty: 'medium',
    },
    {
        puzzle: 'fg----i---h--f-e--e-bd--afh-f--hg--ic------b----f-c-----c-------eiac-gdf-b-----e-',
        solution: 'fgaebhicdihdcfaegbecbdgiafhdfebhgcaicahidefbgbigfacdhegdchefbiaheiacbgdfabfgidhec',
        difficulty: 'medium',
    },
    {
        puzzle: '--d-g-fi---e-ci-d-a----eg-----i---f---bg--ec-e--d--haig----f----ha--------ch-g-e-',
        solution: 'cbdaghfiehgefciadbaifbdeghcdahiecbfgifbghaecdecgdfbhaigeicafdbhbhaeidcgffdchbgiea',
        difficulty: 'medium',
    },
    {
        puzzle: '----d-a---a-ie---di------h-d-e--cg-b-b-e--i----c-i--dh--h-gf--c------b-g--i-ce-a-',
        solution: 'ehfcdgabicabiehfgdigdfbachediehacgfbhbgefdicaafcgibedhbehagfdicfcadhibeggdibcehaf',
        difficulty: 'medium',
    },
    {
        puzzle: '---cfa-ibf---i-------g---f--i--h-cd-gdf--------cd--fb-------bc--gb---dhi---he--g-',
        solution: 'dhecfagibfbgeidhaccaigbhefdbiafhecdggdfbaciehhecdgifbaafhidgbceegbacfdhiicdhebagf',
        difficulty: 'medium',
    },
    {
        puzzle: 'a------g-b--di-a-f--e--ahi----a------bae--------ichbaei---de------c-igd-d-h----ci',
        solution: 'aidhefcgbbhgdicaeffcebgahidheiabgdfccbaefdihggdfichbaeiacgdefbhefbchigdadghfabeci',
        difficulty: 'medium',
    },
    {
        puzzle: '----g-------ci--bg-i-de-af-------beh-----fgdi---eb-f----ah--ig---hg-d---cd--a----',
        solution: 'hacfgbdieefdciahbggibdehafcagfidcbehbceahfgdidhiebgfcafbahceigdiehgfdcabcdgbaiehf',
        difficulty: 'medium',
    },
    {
        puzzle: 'gfbc---dh-a-------d--a--fi--daifc--ech------f-------c-f---e--b---d-----i--igh-d--',
        solution: 'gfbcieadhiahbdfcegdceaghfibbdaifcghechgebdiafeifhagbcdfgcdeihbahbdfcaegiaeighbdfc',
        difficulty: 'medium',
    },
    {
        puzzle: '-e-fh--a-g----ed---a--b-f---ih----dc--------a----g----b---i---dhc-gf-----g------e',
        solution: 'debfhciagghfiaedcbcaidbgfehaihbefgdcfbgcdiehaedchgabifbfaeihcgdhcegfdabiigdacbhfe',
        difficulty: 'hard',
    },
    {
        puzzle: '----i-b---fc--a-h-eb----i-fcieg--ad---hd-e----d--a----f---b-e-i-------b--h--e----',
        solution: 'hageifbcdifcbdagheebdchgiafciegfbadhaghdcefibbdfiahcegfcahbdegideifgchbaghbaeidfc',
        difficulty: 'hard',
    },
    {
        puzzle: '-------hg-----h-d-a-g---ei--ce--dg--dbf---------bfid--hg---f----d--h---c--a-eg---',
        solution: 'bedfiachgficeghbdaahgdbceificehadgfbdbfgceiahgahbfidcehgbcdfaeiediahbfgccfaieghbd',
        difficulty: 'hard',
    },
    {
        puzzle: 'h---f------------i--e---a-h-dhe---a---fh-b----i--c---gf-ga-di--a-i---d-bce------a',
        solution: 'hgcifabdedabgehfciifebdcaghbdheigcafgcfhabeideiadcfhbgfbgahdiecahicgedfbcedfbigha',
        difficulty: 'hard',
    },
    {
        puzzle: 'f----dha----b------a------dic---h------c--egb-----------a-----ed--f-ec-g-fg------',
        solution: 'febigdhachdcbfageigaiehcbfdicegbhadfahfcdiegbbgdaefichcbadigfhedihfaecbgefghcbdia',
        difficulty: 'hard',
    },
    {
        puzzle: 'c-a---i---b--c--ede----g--c-e---dga--c---b--i--gf-----b-----ei------a-cg--ie----a',
        solution: 'cfahdeigbgbhacifedeidbfgahchebcidgafacfgebhdiidgfahcbebacdgfeihfheibadcgdgiehcbfa',
        difficulty: 'hard',
    },
    {
        puzzle: '--a-i---cc-g-------h--e--a--a---ib---d--f--h-----------i---d-f------g-c-dg---b--h',
        solution: 'beagifhdccfghdaibeihdbecfaghafcgibedgdbafechiecidbhagfaihecdgfbfbeihgdcadgcfabeih',
        difficulty: 'hard',
    },
    {
        puzzle: 'i--f--ec------a-fbg-b-i---h-d---ihg-----b---fe---a------d-----i---ie-b-------g---',
        solution: 'iahfdbecgdcehgaifbgfbeicdahbdacfihgechgdbeaifeifgahcbdhbdacfgeifgciedbhaaeibhgfdc',
        difficulty: 'hard',
    },
    {
        puzzle: '--e---c------i--g-------d-hbaf--------cfhe--ie------f-h-d-c-----f-h----c---i-ga--',
        solution: 'fdegbhciaacheidfgbibgcfadehbafdgihcedgcfhebaiehibacgfdhidacfebggfahebidccebidgahf',
        difficulty: 'hard',
    },
    {
        puzzle: '--f-d-i---g--b-a-d--c-a-----c-i---e---eh--g---------ac---------b---i-e----gf--d--',
        solution: 'abfcdhigehgiebfacddecgaibhfgcdifahebfaehcbgdiihbdegfacefabgdcihbdhaicefgcigfhedba',
        difficulty: 'hard',
    },
    {
        puzzle: '-ica------------bh----g--f--g---a---i-e----c-a---f------d--bg------c---e-fg----id',
        solution: 'ficabhdeggeaidfcbhdhbegcifabgfceahdiidebhgacfachdfiegbeadfibghchbigcdfaecfghaebid',
        difficulty: 'expert',
    },
    {
        puzzle: '-h-i------i---------f--bh--b---a--ed-ca------i--f---h--------c----he--f-ab--df---',
        solution: 'ehbicdgafdigafhcbecafegbhdibghcaifedfcadheigbiedfbgahchfebiadcggdihecbfaabcgdfeih',
        difficulty: 'expert',
    },
    {
        puzzle: '-h--c-f-ice-------b--ia--------g-h------e---ff--h---i----b---eh----------ga--f--c',
        solution: 'ahgdcefbiceigfbahdbfdiahcgediefgchabgbhaeidcffachbdeigicfbdagehedbchgifahgaeifbdc',
        difficulty: 'expert',
    },
    {
        puzzle: 'a----db---g-c----f--e-f--i---------i----h-f-d--g---ch---b--e-c-ca------h-d-------',
        solution: 'afchidbegigdcebhafhbegfadicfehdgcabibcaehifgddigbafcheghbfdeicacafibgedhediachgfb',
        difficulty: 'expert',
    },
    {
        puzzle: '------c--g-b--a---------g-h---e----gb--id-----i-f---eb----i---c-he-f-d--a------h-',
        solution: 'edhbgicfagfbchaeidicadefgbhhafebcidgbegidhacfdicfaghebfgdhiebaccheafbdgiabigcdfhe',
        difficulty: 'expert',
    },
    {
        puzzle: '---bf-i-------hc-aa----------g------h--c-e----i----bh----f---g--f-----e---hig-a--',
        solution: 'chebfaidgfgdeihcbaabidcgefhbeghdifachafcbegiddicgafbheicafedhgbgfbahcdeiedhigbacf',
        difficulty: 'expert',
    },
    {
        puzzle: '--c-----d---g-i--h-i----b--ace------d--bh----b--f---------e---------bea--d--a--c-',
        solution: 'gecabhifdfbagdicehhidefcbgaaceigdhbfdgfbheaicbhifcagdeiagcefdhbcfhdibeagedbhagfci',
        difficulty: 'expert',
    },
    {
        puzzle: '-----d-h--h-----a-gb------i-----a--g----eh-c--i--d-----ge---a--d----f-----ab--i--',
        solution: 'iacefdghbehdgibcafgbfhacedicehfbadigfdgiehbcaaibcdgfehbgedhiafcdciagfhbehfabceigd',
        difficulty: 'expert',
    },
    {
        puzzle: '-bi-------c----e---------af---eba-----a-i-g------c--i----h-e--d-e------gc-b--f---',
        solution: 'fbiaegdhcachdfbegiedgchibafgicebafdhbhafidgcedfegchaibiafhgecbdhedbacifgcgbidfhea',
        difficulty: 'expert',
    },
    {
        puzzle: '---i--h-bc----b----g----a----gd-----e--h-f------b---ac-c------ha-----id--i--gd---',
        solution: 'deficahgbchagfbdeibgiedhacffagdicbheebchafgididhbegfacgcdabiefhafbcheidghiefgdcba',
        difficulty: 'expert',
    },
];

},{}],13:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSudoku = void 0;
var get_sudoku_util_1 = require("./utils/get-sudoku.util");
Object.defineProperty(exports, "getSudoku", { enumerable: true, get: function () { return get_sudoku_util_1.getSudoku; } });

},{"./utils/get-sudoku.util":14}],14:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSudoku = void 0;
const base_layout_constant_1 = require("../constants/base-layout.constant");
const difficulty_levels_constant_1 = require("../constants/difficulty-levels.constant");
const get_layout_util_1 = require("./layout/get-layout.util");
const get_seed_util_1 = require("./seed/get-seed.util");
const get_sequence_util_1 = require("./helper/get-sequence.util");
const get_token_map_util_1 = require("./token/get-token-map.util");
const seeds_constant_1 = require("../constants/seeds.constant");
const validate_difficulty_util_1 = require("./validate/validate-difficulty.util");
const getSudoku = (difficulty) => {
    if (difficulty && !(0, validate_difficulty_util_1.validateDifficulty)(difficulty)) {
        throw new Error(`Invalid difficulty, expected one of: ${difficulty_levels_constant_1.DIFFICULTY_LEVELS.join(', ')}`);
    }
    const seed = (0, get_seed_util_1.getSeed)(seeds_constant_1.SEEDS, difficulty);
    const layout = (0, get_layout_util_1.getLayout)(base_layout_constant_1.BASE_LAYOUT);
    const tokenMap = (0, get_token_map_util_1.getTokenMap)();
    const puzzle = (0, get_sequence_util_1.getSequence)(layout, seed.puzzle, tokenMap);
    const solution = (0, get_sequence_util_1.getSequence)(layout, seed.solution, tokenMap);
    return {
        puzzle,
        solution,
        difficulty: seed.difficulty,
    };
};
exports.getSudoku = getSudoku;

},{"../constants/base-layout.constant":10,"../constants/difficulty-levels.constant":11,"../constants/seeds.constant":12,"./helper/get-sequence.util":17,"./layout/get-layout.util":21,"./seed/get-seed.util":33,"./token/get-token-map.util":35,"./validate/validate-difficulty.util":36}],15:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.boardToSequence = void 0;
const boardToSequence = (board) => board.map((row) => row.join('')).join('');
exports.boardToSequence = boardToSequence;

},{}],16:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRandomItem = void 0;
const getRandomItem = (items) => items[Math.floor(Math.random() * items.length)];
exports.getRandomItem = getRandomItem;

},{}],17:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSequence = void 0;
const board_to_sequence_util_1 = require("./board-to-sequence.util");
const populate_layout_util_1 = require("../layout/populate-layout.util");
const replace_tokens_util_1 = require("./replace-tokens.util");
const getSequence = (layout, seedSequence, tokenMap) => (0, board_to_sequence_util_1.boardToSequence)((0, populate_layout_util_1.populateLayout)(layout, (0, replace_tokens_util_1.replaceTokens)(seedSequence, tokenMap)));
exports.getSequence = getSequence;

},{"../layout/populate-layout.util":22,"./board-to-sequence.util":15,"./replace-tokens.util":18}],18:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.replaceTokens = void 0;
const replaceTokens = (sequence, tokenMap) => sequence
    .split('')
    .map((token) => tokenMap[token] || token)
    .join('');
exports.replaceTokens = replaceTokens;

},{}],19:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sortRandom = void 0;
const sortRandom = () => (Math.random() < 0.5 ? 1 : -1);
exports.sortRandom = sortRandom;

},{}],20:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getLayoutBands = void 0;
const getLayoutBands = (layout) => [
    [layout[0], layout[1], layout[2]],
    [layout[3], layout[4], layout[5]],
    [layout[6], layout[7], layout[8]],
];
exports.getLayoutBands = getLayoutBands;

},{}],21:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getLayout = void 0;
const rotate_layout_util_1 = require("./rotate-layout.util");
const shuffle_layout_util_1 = require("./shuffle-layout.util");
const getLayout = (baseLayout) => (0, shuffle_layout_util_1.shuffleLayout)((0, rotate_layout_util_1.rotateLayout)(baseLayout));
exports.getLayout = getLayout;

},{"./rotate-layout.util":27,"./shuffle-layout.util":32}],22:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.populateLayout = void 0;
const populateLayout = (layout, sequence) => layout.map((row) => row.map((cell) => sequence[cell]));
exports.populateLayout = populateLayout;

},{}],23:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rotateLayout0 = void 0;
const rotateLayout0 = (layout) => layout;
exports.rotateLayout0 = rotateLayout0;

},{}],24:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rotateLayout180 = void 0;
const rotateLayout180 = (layout) => layout.map((row) => [...row].reverse()).reverse();
exports.rotateLayout180 = rotateLayout180;

},{}],25:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rotateLayout270 = void 0;
const rotateLayout270 = (layout) => layout[0].map((_row, index) => layout.map((row) => [...row].reverse()[index]));
exports.rotateLayout270 = rotateLayout270;

},{}],26:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rotateLayout90 = void 0;
const rotateLayout90 = (layout) => layout[0].map((_row, index) => layout.map((row) => row[index]).reverse());
exports.rotateLayout90 = rotateLayout90;

},{}],27:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rotateLayout = void 0;
const get_random_item_util_1 = require("../helper/get-random-item.util");
const rotate_layout_0_util_1 = require("./rotate-layout-0.util");
const rotate_layout_180_util_1 = require("./rotate-layout-180.util");
const rotate_layout_270_util_1 = require("./rotate-layout-270.util");
const rotate_layout_90_util_1 = require("./rotate-layout-90.util");
const rotateLayout = (layout) => (0, get_random_item_util_1.getRandomItem)([rotate_layout_0_util_1.rotateLayout0, rotate_layout_90_util_1.rotateLayout90, rotate_layout_180_util_1.rotateLayout180, rotate_layout_270_util_1.rotateLayout270])(layout);
exports.rotateLayout = rotateLayout;

},{"../helper/get-random-item.util":16,"./rotate-layout-0.util":23,"./rotate-layout-180.util":24,"./rotate-layout-270.util":25,"./rotate-layout-90.util":26}],28:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.shuffleLayoutBands = void 0;
const get_layout_bands_util_1 = require("./get-layout-bands.util");
const sort_random_util_1 = require("../helper/sort-random.util");
const shuffleLayoutBands = (layout) => (0, get_layout_bands_util_1.getLayoutBands)(layout).sort(sort_random_util_1.sortRandom).flat();
exports.shuffleLayoutBands = shuffleLayoutBands;

},{"../helper/sort-random.util":19,"./get-layout-bands.util":20}],29:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.shuffleLayoutColumns = void 0;
const rotate_layout_270_util_1 = require("./rotate-layout-270.util");
const rotate_layout_90_util_1 = require("./rotate-layout-90.util");
const shuffle_layout_rows_util_1 = require("./shuffle-layout-rows.util");
const shuffleLayoutColumns = (layout) => (0, rotate_layout_270_util_1.rotateLayout270)((0, shuffle_layout_rows_util_1.shuffleLayoutRows)((0, rotate_layout_90_util_1.rotateLayout90)(layout)));
exports.shuffleLayoutColumns = shuffleLayoutColumns;

},{"./rotate-layout-270.util":25,"./rotate-layout-90.util":26,"./shuffle-layout-rows.util":30}],30:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.shuffleLayoutRows = void 0;
const get_layout_bands_util_1 = require("./get-layout-bands.util");
const sort_random_util_1 = require("../helper/sort-random.util");
const shuffleLayoutRows = (layout) => (0, get_layout_bands_util_1.getLayoutBands)(layout)
    .map((rows) => rows.sort(sort_random_util_1.sortRandom))
    .flat();
exports.shuffleLayoutRows = shuffleLayoutRows;

},{"../helper/sort-random.util":19,"./get-layout-bands.util":20}],31:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.shuffleLayoutStacks = void 0;
const rotate_layout_270_util_1 = require("./rotate-layout-270.util");
const rotate_layout_90_util_1 = require("./rotate-layout-90.util");
const shuffle_layout_bands_util_1 = require("./shuffle-layout-bands.util");
const shuffleLayoutStacks = (layout) => (0, rotate_layout_270_util_1.rotateLayout270)((0, shuffle_layout_bands_util_1.shuffleLayoutBands)((0, rotate_layout_90_util_1.rotateLayout90)(layout)));
exports.shuffleLayoutStacks = shuffleLayoutStacks;

},{"./rotate-layout-270.util":25,"./rotate-layout-90.util":26,"./shuffle-layout-bands.util":28}],32:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.shuffleLayout = void 0;
const shuffle_layout_bands_util_1 = require("./shuffle-layout-bands.util");
const shuffle_layout_columns_util_1 = require("./shuffle-layout-columns.util");
const shuffle_layout_rows_util_1 = require("./shuffle-layout-rows.util");
const shuffle_layout_stacks_util_1 = require("./shuffle-layout-stacks.util");
const shuffleLayout = (layout) => (0, shuffle_layout_columns_util_1.shuffleLayoutColumns)((0, shuffle_layout_rows_util_1.shuffleLayoutRows)((0, shuffle_layout_stacks_util_1.shuffleLayoutStacks)((0, shuffle_layout_bands_util_1.shuffleLayoutBands)(layout))));
exports.shuffleLayout = shuffleLayout;

},{"./shuffle-layout-bands.util":28,"./shuffle-layout-columns.util":29,"./shuffle-layout-rows.util":30,"./shuffle-layout-stacks.util":31}],33:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSeed = void 0;
const get_random_item_util_1 = require("../helper/get-random-item.util");
const get_seeds_by_difficulty_util_1 = require("./get-seeds-by-difficulty.util");
const getSeed = (seeds, difficulty) => (0, get_random_item_util_1.getRandomItem)((0, get_seeds_by_difficulty_util_1.getSeedsByDifficulty)(seeds, difficulty));
exports.getSeed = getSeed;

},{"../helper/get-random-item.util":16,"./get-seeds-by-difficulty.util":34}],34:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSeedsByDifficulty = void 0;
const getSeedsByDifficulty = (seeds, difficulty) => seeds.filter((seed) => !difficulty || seed.difficulty === difficulty);
exports.getSeedsByDifficulty = getSeedsByDifficulty;

},{}],35:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTokenMap = void 0;
const sort_random_util_1 = require("../helper/sort-random.util");
const getTokenMap = () => 'abcdefghi'
    .split('')
    .sort(sort_random_util_1.sortRandom)
    .reduce((acc, token, index) => ({
    ...acc,
    [token]: String(index + 1),
}), {});
exports.getTokenMap = getTokenMap;

},{"../helper/sort-random.util":19}],36:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateDifficulty = void 0;
const difficulty_levels_constant_1 = require("../../constants/difficulty-levels.constant");
// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
const validateDifficulty = (difficulty) => difficulty_levels_constant_1.DIFFICULTY_LEVELS.includes(difficulty);
exports.validateDifficulty = validateDifficulty;

},{"../../constants/difficulty-levels.constant":11}]},{},[1])(1)
});
