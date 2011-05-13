require 'rubygems'
require 'json'
require 'open-uri'

module IME
  class Course
    attr_reader :code, :name, :norwegian_name, :english_name, :version_code, :credit, :credit_type_code, :credit_type_name, :study_level_code, :study_level, :study_level_name, :study_programme_code, :course_type_code, :course_type_name, :grade_rule, :grade_rule_text, :taught_in_spring, :taught_in_autumn, :taught_from_term, :taught_from_year, :taught_in_english, :ouID, :info_types, :assessment, :educational_role, :education_term, :mandatory_activity, :subject_area, :credit_reduction

    def self.find_course(course_code)
      url = BASE_URL + "/course/" + course_code
      result = JSON.parse(open(url).string)
      if result.has_key? 'Error'
        raise "WebServiceError"
      end
      Course.new(result)
    end

    def schedule
      Schedule.find_for_code(self.code)
    end

    protected 

    def initialize(json)
      course = json["course"]
      @code =  course["code"]
      @name = course["name"]
      @norwegian_name = course["newNorwegianName"].nil? ? course["norwegianName"]:course["newNorwegianName"]
      @english_name = course["englishName"]
      @version_code = course["versionCode"]
      @credit = course["credit"]
      @credit_type_code = course["creditTypeCode"]
      @credit_type_name = course["creditTypeName"]
      @study_level_code = course["studyLevelCode"]
      @study_level = course["studyLevel"]
      @study_level_name = course["studyLevelName"]
      @study_programme_code = course["studyProgrammeCode"]
      @course_type_code = course["courseTypeCode"]
      @course_type_name = course["courseTypeName"]
      @grade_rule = course["gradeRule"]
      @grade_rule_text = course["gradeRuleText"]
      @taught_in_spring = course["taughtInSpring"]
      @taught_in_autumn = course["taughtInAutumn"]
      @taught_from_term = course["taughtFromTerm"]
      @taught_from_year = course["taughtFromYear"]
      @taught_in_english = course["taughtInEnglish"]
      @ouID = course["ouID"]
      @info_types = []
      course["infoType"].each do |infotype|
        @info_types << InfoType.new(infotype["code"], infotype["name"], infotype["text"])
      end
      course["assessment"].each do |assessment|
        @assessment = assessment
      end
      @educational_role = course["educationalRole"]
      @educational_role.each do |role|
        role["person"] = Person.new(role["person"])
      end
      @education_term = course["educationTerm"].first
      @mandatory_activity = []
      course["mandatoryActivity"].each do |activity|
        @mandatory_activity << activity["name"]
      end
      @subject_area = []
      course["subjectArea"].each do |area|
        @subject_area << Area.new(area)
      end
    end
  end

  class Area
    attr_reader :code, :name, :norwegian_name, :english_name
    def initialize(hash)
      @code = hash["code"]
      @name = hash["name"]
      @norwegian_name = hash["norwegianName"]
      @english_name = hash["english_name"]
    end
  end

  class InfoType
    attr_reader :code, :name, :text
    def initialize(code, name, text)
      @code = code
      @name = name
      @text = text
    end
    def to_s
      @code
    end
  end
  class Person
    attr_reader :id, :date_of_birth, :gender, :first_name, :last_name, :email, :publication_status, :username, :employee, :affiliated, :student

    def initialize(hash)
      @id = hash["personId"]
      @date_of_birth = hash["dateOfBirth"]
      @gender = hash["gender"]
      @first_name = hash["firstName"]
      @last_name = hash["lastName"]
      @email = hash["email"]
      @publication_status = hash["publicationStatus"]
      @username = hash["username"]
      @employee = hash["employee"]
      @affiliated = hash["affiliated"]
      @student = hash["student"]
    end

    def to_s
      "#{@first_name} #{@last_name}"
    end

  end

  class StudyProgramme
    attr_reader :code
    def initialize(code)
      @code = code
    end
  end

  class Schedule
    attr_reader :code, :activities, :id
    
    def self.find_for_code(code)
      url = BASE_URL + "/schedule/" + code
      result = JSON.parse(open(url).string)
      if result.has_key? 'Error'
        raise "WebServiceError"
      end
      Schedule.new(result)
    end

    def self.find_for_course(course)
      find_for_code(course.code)
    end

    protected
    def initialize(json)
      activities = json["activity"]
      @activities = []
      activities.each do |activity|
        locations = []
        activity["activitySchedules"].first["rooms"].each do |room|
          locations << Location.new(room["location"],room["lydiaCode"])
        end
        @activities << Activity.new(activity["activityDescription"], activity["activityAcronym"], activity["activitySchedules"].first["start"], activity["activitySchedules"].first["end"], activity["activitySchedules"].first["dayNumber"], activity["activitySchedules"].first["weeks"].split(","), locations)
      end
      @code = activities.first["courseCode"]
      @id = activities.first["activityId"]
    end
  end

  class Activity
    # NOTE: day of week is 0 indexed, starting on monday
    attr_reader :description, :acronym, :start, :end, :day_of_week, :weeks, :locations
    def initialize(description, acronym, start, end_time, day_of_week, weeks, locations)
      @description = description
      @acronym = acronym
      @start = start
      @end = end_time
      @day_of_week = day_of_week
      @weeks = weeks
      @locations = locations
    end
  end

  class Location
    attr_reader :name, :code
    def initialize(name, code)
      @name = name
      @code = code
    end
  end

  def self.find_all_courses
    url = BASE_URL + "/course/-"
    file = File.open(open(url).path, "rb")
    json = file.read
    result = JSON.parse(json)
    if result.has_key? 'Error'
      raise "WebServiceError"
    end
    courses = []
    result["course"].each do |course|
      courses << course["code"]
    end
    return courses
  end

  def self.find_course(code)
    Course.find_course(code)
  end

  protected
  BASE_URL = "http://www.ime.ntnu.no/api"

end
