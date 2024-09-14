# Paths
XERCES_PATH = ./xerces/
SRC_DIR = src
GUI_DIR = gui
OBJ_DIR = obj
LIB_DIR = lib
INCLUDE_DIRS = -I ./include -I ./include/entities -I ./include/readers -I ./include/exporters -I $(XERCES_PATH)include/ -I $(GUI_DIR)

# Compiler and linker
# use the 1st CXXFLAGS for release and the 2nd for debug
CXX = g++
CXXFLAGS = -std=c++17 -g -O3 -Wall -fPIC $(INCLUDE_DIRS) `pkg-config --cflags Qt5Widgets`
# CXXFLAGS = -std=c++17 -g -O0 -Wall -fPIC $(INCLUDE_DIRS) `pkg-config --cflags Qt5Widgets`
LDFLAGS = `pkg-config --libs Qt5Widgets` -pthread

# Xerces flags
XERCES_FLAGS = -L $(XERCES_PATH)lib -lxerces-c

# Source files
SRCS = $(filter-out $(SRC_DIR)/main.cpp, $(wildcard $(SRC_DIR)/**/*.cpp) $(wildcard $(SRC_DIR)/*.cpp))
OBJS = $(patsubst $(SRC_DIR)/%.cpp, $(OBJ_DIR)/%.o, $(SRCS))

# GUI files
GUI_SOURCES = $(wildcard $(GUI_DIR)/*.cpp)
GUI_OBJECTS = $(patsubst $(GUI_DIR)/%.cpp, $(OBJ_DIR)/%.o, $(GUI_SOURCES))

# MOC files
MOC_HEADERS = $(wildcard $(GUI_DIR)/*.h)
MOC_SOURCES = $(patsubst $(GUI_DIR)/%.h, $(OBJ_DIR)/moc_%.cpp, $(MOC_HEADERS))
MOC_OBJECTS = $(patsubst $(OBJ_DIR)/%.cpp, $(OBJ_DIR)/%.o, $(MOC_SOURCES))

# Targets
TARGET_REDATAM = redatam
TARGET_REDATAM_LIB = libredatam.a
TARGET_GUI = redatamgui

# Rules
all: $(TARGET_REDATAM) $(TARGET_GUI)
nogui: $(TARGET_REDATAM)

# Build redatam
$(TARGET_REDATAM): $(OBJS) $(OBJ_DIR)/main.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(XERCES_FLAGS) $(LDFLAGS)

$(OBJ_DIR)/main.o: $(SRC_DIR)/main.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

# Build redatam as a static library
$(TARGET_REDATAM_LIB): $(OBJS)
	@mkdir -p $(LIB_DIR)
	ar rcs $(LIB_DIR)/$@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

# Build redatamgui
$(TARGET_GUI): $(filter-out $(OBJ_DIR)/main.o, $(GUI_OBJECTS)) $(MOC_OBJECTS) $(TARGET_REDATAM_LIB) $(OBJ_DIR)/gui_main.o
	$(CXX) $(filter-out $(OBJ_DIR)/main.o, $(GUI_OBJECTS)) $(MOC_OBJECTS) $(OBJ_DIR)/gui_main.o -L$(LIB_DIR) -lredatam $(LDFLAGS) $(XERCES_FLAGS) -o $@

$(OBJ_DIR)/gui_main.o: $(GUI_DIR)/main.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(OBJ_DIR)/%.o: $(GUI_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(OBJ_DIR)/moc_%.cpp: $(GUI_DIR)/%.h
	@mkdir -p $(dir $@)
	moc $< -o $@

clean:
	rm -rf $(OBJ_DIR) $(LIB_DIR) $(TARGET_REDATAM) $(TARGET_GUI)

clang_format=`which clang-format-14`

format: $(shell find . -path ./xerces -prune -o -name '*.h' -print -o -name '*.hpp' -print -o -name '*.cpp' -print)
	@${clang_format} -i $?

.PHONY: all clean nogui
