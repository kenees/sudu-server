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
